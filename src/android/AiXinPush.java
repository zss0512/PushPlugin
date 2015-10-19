package ax.aixintui.plugin;
/**
 * 爱心推插件
 */
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaActivity;
import org.apache.cordova.CordovaArgs;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;

import com.chaoge.door.MainActivity;
import com.ixintui.pushsdk.PushSdkApi;

public class AiXinPush extends CordovaPlugin{
	public static CallbackContext callbackContext;
	public static final String UNKNOW = "unknow";
	@Override
	public boolean execute(String action, JSONArray  args,
			CallbackContext callbackContext) throws JSONException {
		
		if(action.equals("registePush")){//注册推送
			if(callbackContext!=null){
				AiXinPush.callbackContext = callbackContext;
				PushSdkApi.register(getContext(), 1494143734,
						getChannelName("UMENG_CHANNEL"), getverson());
			}
		}
		return super.execute(action, args, callbackContext);
	}
	
	public String getverson() {
		try {
			PackageManager manager = getContext().getPackageManager();
			PackageInfo info = manager.getPackageInfo(getContext().getPackageName(), 0);
			return info.versionName;
		} catch (Exception e) {
		}
		return UNKNOW;
	}

	/**
	 * 获取渠道值
	 * 
	 * @param ctx
	 * @param key
	 *            渠道key
	 * @return 如果没有获取成功，那么返回值为空
	 */
	public String getChannelName(String key) {
		try {
			PackageManager packageManager = getContext().getPackageManager();
			if (packageManager != null) {
				ApplicationInfo applicationInfo = packageManager
						.getApplicationInfo(getContext().getPackageName(),
								PackageManager.GET_META_DATA);
				if (applicationInfo != null) {
					if (applicationInfo.metaData != null) {
						return applicationInfo.metaData.getString(key);
					}
				}
			}
		} catch (Exception e) {
			// e.printStackTrace();
		}
		return UNKNOW;
	}
	
	private Context getContext(){
		return this.cordova.getActivity();
	}

}
