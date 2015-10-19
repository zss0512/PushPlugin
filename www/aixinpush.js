window.PushPlugin = {
	registeAixinPush: function(successCallback, errorCallback) {
		cordova.execute(successCallback, errorCallback, "PushPlugin", "registePush", []);
	},
}
module.exports = PushPlugin;
