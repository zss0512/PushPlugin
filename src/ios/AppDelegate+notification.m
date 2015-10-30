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

static char launchNotificationKey;

@implementation AppDelegate (notification)


- (id) getCommandInstance:(NSString*)className
{
    return [self.viewController getCommandInstance:className];
}

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
    
    if ([UIDevice currentDevice].systemVersion.doubleValue>=8.0) {
        //创建UIUserNotificationSettings，并设置消息的显示类类型
        UIUserNotificationSettings *notiSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge | UIUserNotificationTypeAlert | UIRemoteNotificationTypeSound categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:notiSettings];
    }else{
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes: UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];
    }
	return [self swizzled_init];
}

// This code will be called immediately after application:didFinishLaunchingWithOptions:. We need
// to process notifications in cold-start situations
- (void)createNotificationChecker:(NSNotification *)notification
{
    NSLog(@"createNotificationChecker");
    if (notification) {
        NSLog(@"notification:%@",notification);
    }

}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *plistPath = [[NSBundle mainBundle]pathForResource:@"PushConfig" ofType:@"plist"];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    NSString *iappKey = [data objectForKey:@"AppKey"];
    NSString *isecretKey = [data objectForKey:@"SecretKey"];
    IXTNotification *ixtNotification = [[IXTNotification alloc] init: (iappKey).intValue andToken:deviceToken delegate:nil];
    BOOL flag = [ixtNotification register:isecretKey flag:true];
    NSLog(@"%@,%d",deviceToken,flag);
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
   
    NSLog(@"remote notification: %@",userInfo);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:iPushPluginReceiveNotificaiton
                                                        object:userInfo] ;
    
}

//程序运行在前台，处理IconBadgeNumber值设为0
- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    NSLog(@"active");

    //zero badge
    //application.applicationIconBadgeNumber = 0;

}

- (void)applicationDidEnterBackground:(UIApplication *)application{
    NSLog(@"%f",[[UIApplication sharedApplication] backgroundTimeRemaining]);
}

// The accessors use an Associative Reference since you can't define a iVar in a category
- (NSMutableArray *)launchNotification
{
    return objc_getAssociatedObject(self, &launchNotificationKey);
}

- (void)setLaunchNotification:(NSDictionary *)aDictionary
{
    objc_setAssociatedObject(self, &launchNotificationKey, aDictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)dealloc
{
    self.launchNotification	= nil; // clear the association and release the object
    [[NSNotificationCenter defaultCenter] removeObserver:self]; //监听移除
}


@end
