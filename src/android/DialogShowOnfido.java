package cordova.plugin.onfido;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.Toast;

import com.androidnetworking.AndroidNetworking;
import com.androidnetworking.error.ANError;
import com.androidnetworking.interfaces.JSONObjectRequestListener;
import com.onfido.android.sdk.capture.DocumentType;
import com.onfido.android.sdk.capture.ExitCode;
import com.onfido.android.sdk.capture.Onfido;
import com.onfido.android.sdk.capture.OnfidoConfig;
import com.onfido.android.sdk.capture.OnfidoFactory;
import com.onfido.android.sdk.capture.errors.OnfidoException;
import com.onfido.android.sdk.capture.ui.BaseActivity;
import com.onfido.android.sdk.capture.ui.camera.face.FaceCaptureStep;
import com.onfido.android.sdk.capture.ui.camera.face.FaceCaptureVariant;
import com.onfido.android.sdk.capture.ui.options.CaptureScreenStep;
import com.onfido.android.sdk.capture.ui.options.FlowStep;
import com.onfido.android.sdk.capture.ui.options.MessageScreenStep;
import com.onfido.android.sdk.capture.upload.Captures;
import com.onfido.android.sdk.capture.utils.CountryCode;
import com.onfido.api.client.data.Applicant;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import javax.tools.Diagnostic;

public class DialogShowOnfido extends Activity {

    private Onfido client;
    private String applicantId;
    private boolean firstTime = true;
    private String api_token;
    private String mobile_token;
    private String msj_final;
    private String titulo_final;
    private JSONObject applicant_client = null;
    private JSONObject applicant_check;
    private String automatic_check;
    private String country;
    //private JSONParser parser;

    @Override
    public void onStart() {
        super.onStart();
        // Write your code inside this condition
        // Here should start the process that expects the onActivityResult
        if (firstTime == true) {
            //showToast("firstTime");
            // Do something at first initialization
            // And retrieve the parameters that we sent before in the Main file of the plugin
            Bundle extras = getIntent().getExtras();
            if (extras != null) {
                try {
                    JSONObject onfido = (new JSONObject(extras.getString("Args"))).getJSONObject("Onfido");
                    String texto = onfido.toString();
                    api_token = onfido.getString("Api_Token");
                    mobile_token = onfido.getString("Mobile_Token");
                    applicant_client = onfido.getJSONObject("Aplicant_Client");
                    applicant_check = onfido.getJSONObject("Aplicant_Check");
                    automatic_check = onfido.getString("Automatic_Check");
                    msj_final = onfido.getString("Message_Final");
                    titulo_final = onfido.getString("Titule_Final");
                    country = onfido.getString("country");
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }

            client = OnfidoFactory.create(this).getClient();
            setWelcomeScreen();
        }
    }

    @Override
    protected void onActivityResult(final int requestCode, final int resultCode, final Intent data) {
        firstTime = false;

        super.onActivityResult(requestCode, resultCode, data);
        client.handleActivityResult(resultCode, data, new Onfido.OnfidoResultListener() {
            @Override
            public void userCompleted(Applicant applicant, Captures captures)
            {
                if(automatic_check.equals("true"))
                    startCheck(applicant);
                else {
                    // Send parameters to retrieve in cordova.
                    Intent intent = new Intent();
                    intent.putExtra("response", applicantId);
                    setResult(Activity.RESULT_OK, intent);
                    finish();// Exit of this activity !
                }
            }

            @Override
            public void userExited(ExitCode exitCode, Applicant applicant) {
                showToast("User cancelled.");
                // Send parameters to retrieve in cordova.
                Intent intent = new Intent();
                intent.putExtra("response", "");
                setResult(Activity.RESULT_OK, intent);
                finish();// Exit of this activity !
            }

            @Override
            public void onError(OnfidoException e, Applicant applicant) {
                e.printStackTrace();
                showToast("Unknown error");
            }
        });
    }

    private void showToast(String message) {
        Toast.makeText(DialogShowOnfido.this, message, Toast.LENGTH_LONG).show();
    }

    private void startCheck(Applicant applicant) {
        //Call your back end to initiate the check
        //completedCheck();
        completedCheck(new JSONObjectRequestListener() {
            @Override
            public void onResponse(JSONObject response) {

                // Send parameters to retrieve in cordova.
                Intent intent = new Intent();
                intent.putExtra("response", response.toString());
                setResult(Activity.RESULT_OK, intent);
                finish();// Exit of this activity !
            }

            @Override
            public void onError(ANError anError) {
                showToast("On Error");
                //showToast(anError.fillInStackTrace());
            }
        });
    }

    private void setWelcomeScreen() {
        if(country.equals("SLV")){
            final FlowStep[] flowStepsSvlWithOptions = new FlowStep[]{
                new CaptureScreenStep(DocumentType.NATIONAL_IDENTITY_CARD, CountryCode.SV),
                new FaceCaptureStep(FaceCaptureVariant.VIDEO),
                new MessageScreenStep(titulo_final, msj_final, "Start Check")
            };
            startFlow(flowStepsSvlWithOptions);
        }
        if(country.equals("CRI")){
            final FlowStep[] flowStepsCrcWithOptions = new FlowStep[]{
                new CaptureScreenStep(DocumentType.NATIONAL_IDENTITY_CARD, CountryCode.CR),
                new FaceCaptureStep(FaceCaptureVariant.VIDEO),
                new MessageScreenStep(titulo_final, msj_final, "Start Check")
            };
            startFlow(flowStepsCrcWithOptions);
        }
        
        if(country.equals("GTM")){
            final FlowStep[] flowStepsGtmWithOptions = new FlowStep[]{
                new CaptureScreenStep(DocumentType.NATIONAL_IDENTITY_CARD, CountryCode.GTM),
                new FaceCaptureStep(FaceCaptureVariant.VIDEO),
                new MessageScreenStep(titulo_final, msj_final, "Start Check")
            };
            startFlow(flowStepsGtmWithOptions);
        }
    }

    private void startFlow(final FlowStep[] flowSteps) {
        createApplicant(new JSONObjectRequestListener() {
            @Override
            public void onResponse(JSONObject response) {
                try {
                    applicantId = response.getString("id");

                    OnfidoConfig.Builder onfidoConfigBuilder = OnfidoConfig.builder().withApplicant(applicantId).withToken(mobile_token);

                    if (flowSteps != null) {
                        onfidoConfigBuilder.withCustomFlow(flowSteps);
                    }

                    OnfidoConfig onfidoConfig = onfidoConfigBuilder.build();
                    client.startActivityForResult(DialogShowOnfido.this, 1, onfidoConfig);

                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }

            @Override
            public void onError(ANError anError) {
            }
        });
    }

    private void createApplicant(JSONObjectRequestListener listener) {
        /*
        $ curl https://api.onfido.com/v2/applicants \
          -H 'Authorization: Token token=YOUR_API_TOKEN' \
          -d 'first_name=Theresa' \
          -d 'last_name=May'
         */

        AndroidNetworking.post("https://api.onfido.com/v2/applicants")
                .addJSONObjectBody(applicant_client)
                .addHeaders("Accept", "application/json")
                .addHeaders("Authorization", "Token token=" + api_token)
                .build()
                .getAsJSONObject(listener);
    }

    private void completedCheck(JSONObjectRequestListener listener) {
        /*
        $ curl https://api.onfido.com/v2/applicants/YOUR_APPLICANT_ID/checks \
        -H 'Authorization: Token token=YOUR_API_TOKEN' \
        -d 'type=express' \
        -d 'reports[][name]=document' \
        -d 'reports[][name]=facial_similarity' \
        -d 'reports[][variant]=standard'
        */

        AndroidNetworking.post("https://api.onfido.com/v2/applicants/" + this.applicantId + "/checks")
                .addJSONObjectBody(applicant_check)
                .addHeaders("Accept", "application/json")
                .addHeaders("Authorization", "Token token=" + api_token)
                .build()
                .getAsJSONObject(listener);
    }
}

