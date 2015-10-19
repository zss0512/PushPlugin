package ax.aixintui.plugin;
import org.json.JSONObject;

import com.ixintui.pushsdk.SdkConstants;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences.Editor;
import android.util.Log;

public class PushReceiver extends BroadcastReceiver {

	private static final String TAG = "PushReceiver";
	

	@Override
	public void onReceive(Context context, Intent intent) {
		String action = intent.getAction();
		// 透传消息
		if (action.equals(SdkConstants.MESSAGE_ACTION)) {
			String msg = intent.getStringExtra(SdkConstants.MESSAGE);
			String extra = intent.getStringExtra(SdkConstants.ADDITION);
			Intent intent2 = new Intent(context, NotifService.class);
			intent2.putExtra("msg", msg);
			context.startService(intent2);
			
			AiXinPush.callbackContext.success(extra);
		}
		// SDK API的异步返回结果
		else if (action.equals(SdkConstants.RESULT_ACTION)) {
			// API 名称
			String cmd = intent.getStringExtra(SdkConstants.COMMAND);
			// 返回值，0为成功，否则失败
			int code = intent.getIntExtra(SdkConstants.CODE, 0);
			if (code != 0) {
				// 错误信息
				String error = intent.getStringExtra(SdkConstants.ERROR);
				Log.d(TAG, "command is: " + cmd + " result error: " + error);
			} else {
				Log.d(TAG, "command is: " + cmd + "result OK");
			}
			// 附加结果，比如添加成功的tag， 比如推送是否暂停等
			String extra = intent.getStringExtra(SdkConstants.ADDITION);
			if (extra != null) {
				Log.d(TAG, "result extra: " + extra);
			}
		}
		
		// 自定义通知点击事件
		else if (action.equals("com.action.notif.CLICK")) {
			if (AiXinPush.callbackContext!=null) {
				AiXinPush.callbackContext.success("wwww");
			}else{
				Intent intent2 = intent.getParcelableExtra("realIntent");
				context.startActivity(intent2);
			}
		}

	}

}
