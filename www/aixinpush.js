window.aiXinPushServer = {
	registeAixinPush: function(successCallback, errorCallback) {
		cordova.exec(successCallback, errorCallback, "aiXinPushServer", "registePush", []);
	},
}
module.exports = aiXinPushServer;
