//
//  AppDelegate+notification.m
//  pushtest
//
//  Created by Robert Easterday on 10/26/12.
//
//

#import "AppDelegate+notification.h"
#import "PushPlugin.h"
#import <objc/runtime.h>
#import "IXTNotification.h"

@implementation AppDelegate (notification)

// its dangerous to override a method from within a category.
// Instead we will use method swizzling. we set this up in the load call.
+ (void)load
{
    Method original, swizzled;
    
    original = class_getInstanceMethod(self, @selector(init));
    swizzled = class_getInstanceMethod(self, @selector(swizzled_init));
    method_exchangeImplementations(original, swizzled);
}

- (AppDelegate *)swizzled_init
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(createNotificationChecker:)
               name:@"UIApplicationDidFinishLaunchingNotification" object:nil];
	
	// This actually calls the original init method over in AppDelegate. Equivilent to calling super
	// on an overrided method, this is not recursive, although it appears that way. neat huh?
	return [self swizzled_init];
}

// This code will be called immediately after application:didFinishLaunchingWithOptions:. We need
// to process notifications in cold-start situations
- (void)createNotificationChecker:(NSNotification *)notification
{
    if ([UIDevice currentDevice].systemVersion.doubleValue>=8.0) {
        //创建UIUserNotificationSettings，并设置消息的显示类类型
        UIUserNotificationSettings *notiSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIRemoteNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notiSettings];
    }else{
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
    NSLog(@"createNotificationChecker");
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *plistPath = [[NSBundle mainBundle]pathForResource:@"PushConfig" ofType:@"plist"];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    NSString *iappKey = [data objectForKey:@"AppKey"];
    NSString *isecretkey = [data objectForKey:@"SecretKey"];
    NSLog(@"%@,%@",iappKey,isecretkey);
    IXTNotification *ixtNotification = [[IXTNotification alloc] init: (iappKey).intValue andToken:deviceToken delegate:nil];
    BOOL flag = [ixtNotification register:isecretkey flag:true];
    NSLog(@"%@,%d",deviceToken,flag);
    //delegate是http的回调,可参照HttpDelegate.h实现
    NSUserDefaults *userToken=[NSUserDefaults standardUserDefaults];
    [userToken setValue:deviceToken forKey:@"deviceToken"];
    [userToken synchronize];//把数据同步到本地
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed To Register For RemoteNotifications:%@",error);    
}

//当应用在前台运行中，收到远程通知时，会回调这个方法。
//当应用在后台状态时，点击push消息启动应用，也会回调这个方法。
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {

//    NSLog(@"didReceiveNotification");
//    NSLog(@"%@",userInfo);
//    NSString *classType = [userInfo objectForKey:@"classType"];
//    NSString *detailId = [userInfo objectForKey:@"detailId"];
//    NSString *loadPage = [NSString stringWithFormat:@"index.html?%@%@",classType,detailId];
//    // Get application state for iOS4.x+ devices, otherwise assume active
//    UIApplicationState appState = UIApplicationStateActive;
//    if ([application respondsToSelector:@selector(applicationState)]) {
//        appState = application.applicationState;
//    }
//    
//    if (appState == UIApplicationStateActive) {
//        self.viewController.startPage = loadPage;
//    } else {
//        //send it to JS
//        //self.launchNotification = userInfo;
//        //self.viewController.startPage = loadPage;
//    }
    NSLog(@"remote notification: %@",[userInfo description]);
    NSString* alertStr = nil;
    NSDictionary *apsInfo = [userInfo objectForKey:@"aps"];
    NSObject *alert = [apsInfo objectForKey:@"alert"];
    if ([alert isKindOfClass:[NSString class]])
    {
        alertStr = (NSString*)alert;
    }
    else if ([alert isKindOfClass:[NSDictionary class]])
    {
        NSDictionary* alertDict = (NSDictionary*)alert;
        alertStr = [alertDict objectForKey:@"body"];
    }
    application.applicationIconBadgeNumber = [[apsInfo objectForKey:@"badge"] integerValue];
    if ([application applicationState] == UIApplicationStateActive && alertStr != nil)
    {
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Pushed Message" message:alertStr delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
    NSString *classType = [userInfo objectForKey:@"classtype"];
    NSString *detailId = [userInfo objectForKey:@"id"];
    NSString *loadPage = [NSString stringWithFormat:@"index.html?%@%@",classType,detailId];
    self.viewController.startPage = loadPage;
}
//程序运行在前台，处理IconBadgeNumber值设为0
- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    NSLog(@"active");

    //zero badge
    //application.applicationIconBadgeNumber = 0;

}

@end
