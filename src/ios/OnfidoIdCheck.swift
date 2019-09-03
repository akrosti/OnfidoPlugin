import Onfido
import Alamofire
import Foundation
import UIKit
class OnResult : NSObject{
    public var Error: Bool?=false
    public var Cancel: Bool?=false
    public var Id: String? = ""
    public var ErrorDescription: String? = ""
    func getValues() -> [String: AnyObject] {
        return ["error": self.Error as AnyObject,
                "cancel": self.Cancel as AnyObject,
                "id": self.Id as AnyObject,
                "errordescription": self.ErrorDescription as AnyObject]
    }
}
//Clase proxy para acceder al sdk de onfido.
//aalpizar
//Release 00
//28/2/2019
@objc(OnfidoIdCheck) class OnfidoIdCheck : CDVPlugin {
    //variables para el api de onfido.
    private var _token:String = "" //almacena el token.
    private var _Titule_Final:String = "" // sin uso
    private var _First_Name:String = "" // almacena el nombre del cliente
    private var _Last_Name:String = "" // almacena el apellido del cliente
    private var _Message_Final:String = "" // sin uso
    private var _Aplicant_Client:String = "" // almacena el id del cliente asignado por onfido.
    var _ResultFlow: OnResult = OnResult()
    //constantes de campos del json de onfido.
    var Key_Token = "Mobile_Token"
    var Key_Titule_Final = "Titule_Final"
    var Key_Message_Final = "Message_Final"
    var Key_Aplicant_Client = "Aplicant_Client"
    var Key_First_Name = "First_name"
    var Key_Last_Name = "Last_name"
    var Key_Aplicant_Check = "Aplicant_Check"
    var Key_Reports = "reports"
    var Key_Type = "type"
    var Key_ContryCode: String = "SLV" // Codigo de pais
    var Key_Country: String = "country"
    var Result: Bool = false
    //Variables para colores.
    var Key_PrimaryColor: String = ""
    var Key_PrimaryTitleColor: String = ""
    var Key_PrimaryBackgroundPressedColor: String = ""
    var Key_secondaryBackgroundPressedColor: String = ""
    var Key_fontRegular = ""
    var Key_fontBold = ""
    var dictAplicant_Client: [String: Any] = [String: Any]()
    func json(from object:Any) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: object, options: []) else {
            return nil
        }
        return String(data: data, encoding: String.Encoding.utf8)
    }
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        if ((cString.characters.count) != 6) {
            return UIColor.gray
        }
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    //Metodo para leer el archivo json que se envia.
    func readJsonFrom(object: String)-> [String: Any]? {
        let data: Data = object.data(using: .utf8)!
        do {
            let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            for (key, value) in dict! {
                let valueStr = self.json(from: value)
                let dataOnfidoInit: Data = (valueStr as! String).data(using: .utf8)!
                let dict2 = try JSONSerialization.jsonObject(with: dataOnfidoInit, options: []) as? [String: Any]
                for (keyOnf, valueOnf) in dict2! {
                    if (keyOnf.contains(self.Key_Token))
                    {
                        self._token = String(describing: valueOnf)
                    }
                    else if(keyOnf.contains(self.Key_Titule_Final))
                    {
                        self._Titule_Final = String(describing: valueOnf)
                    }
                    else if(keyOnf.contains(self.Key_Message_Final))
                    {
                        self._Message_Final = String(describing: valueOnf)
                    }
                    else if(keyOnf.contains(self.Key_Aplicant_Check))
                    {
                        let valueAplication_Check = self.json(from: valueOnf)
                        let dataAplicant_Check: Data = (valueAplication_Check as! String).data(using: .utf8)!
                        let dictAplicant_Check = try JSONSerialization.jsonObject(with: dataAplicant_Check, options: []) as? [String: Any]
                        for (keyAplicant_Report, valueAplicant_Report) in dictAplicant_Check! {
                            if (keyAplicant_Report.contains("reports"))
                            {
                                let value_Report = self.json(from: valueAplicant_Report)
                                let dataAplicant_Report: Data = (value_Report as! String).data(using: .utf8)!
                            }
                        }
                    }
                    else if(keyOnf.contains(self.Key_Aplicant_Client))
                    {
                        let valueAplication_Client = self.json(from: valueOnf)
                        let dataAplicant_Client: Data = (valueAplication_Client as! String).data(using: .utf8)!
                        dictAplicant_Client = try (JSONSerialization.jsonObject(with: dataAplicant_Client, options: []) as? [String: Any])!
                        for (keyAplicant_Client, valueAplicant_Client) in dictAplicant_Client {
                            if (keyAplicant_Client.contains(self.Key_First_Name))
                            {
                                self._First_Name = String(describing: valueAplicant_Client)
                            }
                            if (keyAplicant_Client.contains(self.Key_Last_Name))
                            {
                                self._Last_Name = String(describing: valueAplicant_Client)
                            }
                            if (keyAplicant_Client.contains(self.Key_Country))
                            {
                                self.Key_ContryCode = String(describing: valueAplicant_Client)
                            }
                        }
                    }
                }
            }
        } catch let error {
            print("error : \(error)")
        }
        return nil
    }
    // metodo para crear el cliente.
    private func createClient(_ completionHandler: @escaping (String?, Error?) -> Void) {
        let applicant: Parameters = [
            "first_name": self._First_Name,
            "last_name": self._Last_Name
        ]
        let headers: HTTPHeaders = [
            "Authorization": "Token token=\(self._token)",
            "Accept": "application/json"
        ]
        Alamofire.request(
            "https://api.onfido.com/v2/applicants",
            method: .post,
            parameters: self.dictAplicant_Client,
            encoding: JSONEncoding.default,
            headers: headers).responseJSON { (response: DataResponse<Any>) in
                guard response.error == nil else {
                    completionHandler(nil, response.error)
                    return
                }
                let response = response.result.value as! [String: Any]
                guard response.keys.contains("error") == false else {
                    //implementar en caso de error.
                    // completionHandler(nil, ApplicantError.apiError(response["error"] as! [String : Any]
                    return
                }
                // En caso de exito.
                let _ApplicantId = response["id"] as! String
                completionHandler(_ApplicantId, nil)
        }
    }

    // Metodo que invoca la ejecucion de los flujos de onfido.
    private func runFlow(_ completionHandler: @escaping (Error?) -> Void){
        let responseHandler: (OnfidoResponse) -> Void = { response in

            if case let OnfidoResponse.success(results) = response {
                self._ResultFlow.Error = false;
                completionHandler(nil)
            } else if case let OnfidoResponse.error(innererror) = response {
                self._ResultFlow.Error = true
                switch innererror {
                case OnfidoFlowError.cameraPermission:
                    self._ResultFlow.ErrorDescription = "cameraPermission";
                case OnfidoFlowError.failedToWriteToDisk:
                    self._ResultFlow.ErrorDescription = "spaceError";
                case OnfidoFlowError.microphonePermission:
                    self._ResultFlow.ErrorDescription = "microphonePermission"
                case OnfidoFlowError.upload(let OnfidoApiError):
                    self._ResultFlow.ErrorDescription = "errorUpload"
                case OnfidoFlowError.exception(withError: let error, withMessage: let message):
                    self._ResultFlow.ErrorDescription = "Error"
                default: break
                }
                completionHandler(nil)
            } else if case OnfidoResponse.cancel = response {
                self._ResultFlow.Error  = false
                self._ResultFlow.Cancel = false
                completionHandler(nil)
            }
        }
        let appearance = Appearance(

            primaryColor: self.hexStringToUIColor(hex: self.Key_PrimaryColor),
            primaryTitleColor: self.hexStringToUIColor(hex: self.Key_PrimaryTitleColor),
            primaryBackgroundPressedColor: self.hexStringToUIColor(hex: self.Key_PrimaryBackgroundPressedColor),
            secondaryBackgroundPressedColor: self.hexStringToUIColor(hex: self.Key_secondaryBackgroundPressedColor)

        )


        let config = try! OnfidoConfig.builder()
            .withToken(_token)
            .withApplicantId(self._Aplicant_Client)
            .withDocumentStep(ofType: .nationalIdentityCard, andCountryCode: Key_ContryCode)
            .withFaceStep(ofVariant: .video)
            .withCustomLocalization(andTableName:"Localizable")
            .withAppearance(appearance)
            .build()

        let onfidoFlow = OnfidoFlow(withConfiguration: config)
            .with(responseHandler: responseHandler)

        do {

            let onfidoRun = try onfidoFlow.run()
            onfidoRun.modalPresentationStyle = .formSheet // to present modally
            self.viewController?.present(onfidoRun,animated: true,completion: nil)

        } catch let error {

        }
    }
    //METODO GENERICO PARA MOSTRAR MENSAJES DE ERROR NATIVO.
    private func showErrorMessage(forError error: Error) {

        let alert = UIAlertController(title: "Errored", message: "Onfido SDK Errored \(error)", preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: { _ in })
        alert.addAction(alertAction)
        //self.present(alert, animated: true)
        self.viewController?.present(alert,animated: true,completion: nil)
    }

    enum ApplicantError: Error {
        case apiError([String:Any])
    }
    @objc(startSdk:)
    func startSdk(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        // INICIALIZACION DE VARIABLES DE LAS LLAVES DEL JSON RECIBIDO.
        Key_Token = "Mobile_Token"
        Key_Titule_Final = "Titule_Final"
        Key_Message_Final = "Message_Final"
        Key_Aplicant_Client = "Aplicant_Client"
        Key_First_Name = "first_name"
        Key_Last_Name = "last_name"
        Key_Aplicant_Check = "Aplicant_Check"
        Key_Reports = "reports"
        Key_Type = "type"
        Key_PrimaryColor = "#00b7f1"
        Key_PrimaryTitleColor = "#ffffff"
        Key_PrimaryBackgroundPressedColor = "#00b7f1"
        Key_secondaryBackgroundPressedColor = "#ffffff"
        Key_fontRegular = "OpenSans-Bold"
        Key_fontBold = "OpenSans-Bold"
        Key_Country = "country"

        _ResultFlow = OnResult()
        let jsonr = self.json(from:command.arguments[0])

        let jsonq = self.readJsonFrom(object:jsonr!)
        if jsonr != nil {
            self.createClient{ (applicantId, error) in
                guard error == nil else {

                    return
                }
                self._Aplicant_Client = applicantId!
                self.runFlow{   (error ) in

                    guard error == nil else {

                        return
                    }
                    if (self._ResultFlow.Error == false)
                    {
                        self._ResultFlow.Id = applicantId
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: self._ResultFlow.getValues(), options: .prettyPrinted)

                            let theJSONText = String(data: jsonData,
                                                     encoding: .ascii)
                            pluginResult = CDVPluginResult(
                                status: CDVCommandStatus_OK,
                                messageAs: applicantId
                            )

                        } catch {
                            print(error.localizedDescription)
                        }
                    }else
                    {
                        self._ResultFlow.Id = applicantId
                        do {
                            let jsonData = try JSONSerialization.data(withJSONObject: self._ResultFlow.getValues(), options: .prettyPrinted)

                            let theJSONText = String(data: jsonData,
                                                     encoding: .ascii)
                            var oJsonResult = self.json(from: self._ResultFlow)
                            pluginResult = CDVPluginResult(
                                status: CDVCommandStatus_ERROR,
                                messageAs: applicantId
                            )
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                    self.commandDelegate!.send(
                        pluginResult,
                        callbackId: command.callbackId
                    )
                }
            }
        }
    }
}
