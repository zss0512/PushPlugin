package ax.aixintui.plugin;

import com.chaoge.door.MainActivity;
import com.chaoge.door.R;

import android.annotation.SuppressLint;
import android.app.Notification;
import android.app.Notification.Builder;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences.Editor;
import android.os.IBinder;
import android.util.Log;

public class NotifService extends Service {
	private final static String TAG = NotifService.class.getSimpleName();
	private String messge = null;
	private final static int ID = 888;

	@Override
	public void onCreate() {
		super.onCreate();
		Log.d(TAG, "444445555onCreate");
	}

	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		if (intent != null) {
			messge = intent.getStringExtra("msg");
		}
		Log.d(TAG, "444445555messge" + messge);
		if (messge != null) {
			if (messge.startsWith("news&") || messge.startsWith("product&")
					|| messge.startsWith("suggest&")) {
				saveShadStorage("extro", messge.split("&")[0]);
				if (messge.startsWith("news&")) {
					messge = messge.replace("news&", "");
				} else if (messge.startsWith("product&")) {
					messge = messge.replace("product&", "");
				} else if (messge.startsWith("suggest&")) {
					messge = messge.replace("suggest&", "");
				}
			}

			//必须pass掉所有异常，不能因为有问题而导致程序死掉， add by chensy at 2015-6-11 begin
			try {
				showNotif();
			} catch (Exception e) {
//				if(BuildConfig.DEBUG){
					e.printStackTrace();
//				}
			}
			//必须pass掉所有异常，不能因为有问题而导致程序死掉， add by chensy at 2015-6-11 end
		}

		return START_REDELIVER_INTENT;
	}

	@SuppressLint("NewApi") 
	public void showNotif() {

		Intent openintent = new Intent();
		openintent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		openintent.setClass(getApplication(), MainActivity.class);
		
		Intent clickIntent = new Intent(getApplication(), PushReceiver.class);
		clickIntent.setAction("com.action.notif.CLICK");
		clickIntent.putExtra("realIntent", openintent);
		PendingIntent pi = PendingIntent.getBroadcast(getApplication(), ID, clickIntent, PendingIntent.FLAG_UPDATE_CURRENT);  
		NotificationManager nfm = (NotificationManager) getApplication().getSystemService(Context.NOTIFICATION_SERVICE);
		Builder builder = new Notification.Builder(getApplication())
				.setTicker("超哥报价提示：系统有最新消息，请注意查看！")
				.setWhen(System.currentTimeMillis())
				.setSmallIcon(R.drawable.icon).setContentIntent(pi)
				.setContentTitle("超哥报价").setContentText(messge)
				.setDefaults(Notification.DEFAULT_SOUND).setAutoCancel(true);
		
		if(builder == null){
			return;
		}
		Notification notification = builder.build();
		nfm.notify(ID, notification);
	}

	public void saveShadStorage(String flag, String value) {
		// Log.d(TAG, "444445555" + flag + value);
		Editor editor = getApplication().getSharedPreferences("H5D34B0F9_storages",
				Context.MODE_PRIVATE).edit();
		editor.putString(flag, value);
		editor.commit();
	}

	@Override
	public IBinder onBind(Intent intent) {
		//do nothing.
		return null;
	}

}
