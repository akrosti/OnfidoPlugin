package cordova.plugin.onfido;

import android.app.Activity;
import android.content.Intent;
import android.widget.Toast;
import android.os.Bundle;

import com.onfido.android.sdk.capture.Onfido;
import com.onfido.api.client.OnfidoAPI;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.PluginResult;
import org.apache.cordova.PluginResult.Status;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class OnfidoIdCheck extends CordovaPlugin {
    private static final String TAG = "MyCordovaPlugin";
    private Onfido client;
    private OnfidoAPI onfidoAPI;
    private CallbackContext PUBLIC_CALLBACKS = null;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

        //showToast(args.getJSONObject(0));
        PUBLIC_CALLBACKS = callbackContext;
        Activity context = this.cordova.getActivity();
        final JSONObject arg_object = args.getJSONObject(0);

        if (action.equals("startSdk")) {
            // The intent expects as first parameter the given name for the activity in your plugin.xml
            Intent intent = new Intent("cordova.plugin.onfido.DialogShowOnfido");
            // Send some info to the activity to retrieve it later
            //showToast(arg_object.toString());
            intent.putExtra("Args", arg_object.toString());

            // Now, cordova will expect for a result using startActivityForResult and will be handle by the onActivityResult.
            cordova.startActivityForResult((CordovaPlugin) this, intent, 0);
        }

        // Send no result, to execute the callbacks later
        PluginResult pluginResult = new PluginResult(PluginResult.Status.NO_RESULT);
        pluginResult.setKeepCallback(true); // Keep callback

        return true;
    }

    @Override
    public void onActivityResult(final int requestCode, final int resultCode, final Intent data) {

        if (resultCode == cordova.getActivity().RESULT_OK) {
            Bundle extras = data.getExtras();// Get data sent by the Intent
            String response = extras.getString("response"); // data parameter will be send from the other activity.
            PluginResult resultado = new PluginResult(PluginResult.Status.OK, response);
            resultado.setKeepCallback(true);
            PUBLIC_CALLBACKS.sendPluginResult(resultado);
            return;
        } else if (resultCode == cordova.getActivity().RESULT_CANCELED) {
            PluginResult resultado = new PluginResult(PluginResult.Status.OK, "canceled action, process this in javascript");
            resultado.setKeepCallback(true);
            PUBLIC_CALLBACKS.sendPluginResult(resultado);
            return;
        }

        // Handle other results if exists.
        super.onActivityResult(requestCode, resultCode, data);
    }

    private void showToast(String message) {
        Toast.makeText(this.cordova.getActivity(), message, Toast.LENGTH_LONG).show();
    }
}
