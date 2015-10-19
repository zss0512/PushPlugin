window.aiXinPushServer = {
	registeAixinPush: function(successCallback, errorCallback) {
		cordova.execute(successCallback, errorCallback, "aiXinPushServer", "registePush", []);
	},
}
module.exports = aiXinPushServer;
