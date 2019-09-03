var exec = require('cordova/exec');

module.exports.startSdk = function (arg0, success, error) {
    exec(success, error, 'OnfidoIdCheck', 'startSdk', [arg0]);
};