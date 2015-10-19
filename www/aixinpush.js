window.aiXinPushServer = {
	registeAixinPush: function(successCallback, errorCallback) {
		cordova.execute(successCallback, errorCallback, "aiXinPushServer", "registePush", []);
		console.log("PushNotification.register ");
	};	
	
	register = function(successCallback, errorCallback, options) {
    		if (errorCallback == null) { errorCallback = function() {}}

	 	if (typeof errorCallback != "function")  {
        		console.log("PushNotification.register failure: failure parameter not a function");
        		return
	 	}

    		if (typeof successCallback != "function") {
			console.log("PushNotification.register failure: success callback parameter must be a function");
        		return
    		}
		cordova.exec(successCallback, errorCallback, "PushPlugin", "register", [options]);
	};
	unregister = function(successCallback, errorCallback) {
    		if (errorCallback == null) { errorCallback = function() {}}

    		if (typeof errorCallback != "function")  {
        		console.log("PushNotification.unregister failure: failure parameter not a function");
        		return
    		}

    		if (typeof successCallback != "function") {
        		console.log("PushNotification.unregister failure: success callback parameter must be a function");
        		return
    		}
     		cordova.exec(successCallback, errorCallback, "PushPlugin", "unregister", []);
	};
	setApplicationIconBadgeNumber = function(successCallback, errorCallback, badge) {
    		if (errorCallback == null) { errorCallback = function() {}}

    		if (typeof errorCallback != "function")  {
        		console.log("PushNotification.setApplicationIconBadgeNumber failure: failure parameter not a function");
        		return
    		}

		 if (typeof successCallback != "function") {
        		console.log("PushNotification.setApplicationIconBadgeNumber failure: success callback parameter must be a function");
        		return
    		}
		cordova.exec(successCallback, errorCallback, "PushPlugin", "setApplicationIconBadgeNumber", [{badge: badge}]);
	};
}
module.exports = aiXinPushServer;

//-------------------------------------------------------------------
