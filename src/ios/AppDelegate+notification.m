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
	if (notification)
	{
		NSDictionary *launchOptions = [notification userInfo];
		if (launchOptions)
			self.launchNotification = [launchOptions objectForKey: @"UIApplicationLaunchOptionsRemoteNotificationKey"];
	}
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
    [pushHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"Failed To Register For RemoteNotifications:%@",error);    
    PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
    [pushHandler didFailToRegisterForRemoteNotificationsWithError:error];
}

//点击某条远程通知时调用的委托 如果界面处于打开状态,那么此委托会直接响应
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    NSLog(@"didReceiveNotification");
    // Get application state for iOS4.x+ devices, otherwise assume active
    UIApplicationState appState = UIApplicationStateActive;
    if ([application respondsToSelector:@selector(applicationState)]) {
        appState = application.applicationState;
    }
    
    if (appState == UIApplicationStateActive) {
        PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
        pushHandler.notificationMessage = userInfo;
        pushHandler.isInline = YES;
        [pushHandler notificationReceived];
    } else {
        //send it to JS
        self.launchNotification = userInfo;
        PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
        pushHandler.notificationMessage = userInfo;
        [pushHandler notificationReceived];
    }
}
//程序运行在前台，处理IconBadgeNumber值设为0
- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    NSLog(@"active");
    
    //zero badge
    application.applicationIconBadgeNumber = 0;

    if (![self.viewController.webView isLoading] && self.launchNotification) {
        PushPlugin *pushHandler = [self getCommandInstance:@"PushPlugin"];
		
        pushHandler.notificationMessage = self.launchNotification;
        self.launchNotification = nil;
        [pushHandler performSelectorOnMainThread:@selector(notificationReceived) withObject:pushHandler waitUntilDone:NO];
    }
}

// The accessors use an Associative Reference since you can't define a iVar in a category
// http://developer.apple.com/library/ios/#documentation/cocoa/conceptual/objectivec/Chapters/ocAssociativeReferences.html
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
}

@end
