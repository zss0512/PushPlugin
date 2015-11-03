//
//  PushPlugin.m
//  ChaoGeDoor
//
//  Created by jwt on 15/10/8.
//
//

#import "PushPlugin.h"
#import "IXTNotification.h"
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>

@implementation PushPlugin

@synthesize webView;
@synthesize callback;
@synthesize callbackId;
@synthesize notificationMessage;
@synthesize extra_dic;


- (CDVPlugin*)initWithWebView:(UIWebView*)theWebView{
    if (self=[super initWithWebView:theWebView]) {
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        //监听一个通知，当收到通知时，调用networkDidReceiveNotification方法
        [defaultCenter addObserver:self
                          selector:@selector(networkDidReceiveNotification:)
                              name:iPushPluginReceiveNotificaiton
                            object:nil];
    }
    return self;
}

/**
 *  监听到通知时调用的方法
 *
 *  @param notification 通知的处理
 */
- (void)networkDidReceiveNotification:(NSNotification *)notification{
    NSDictionary *object = [notification object];
    //NSDictionary *extra_dic = nil;//extra的内容
    NSString *type = nil;
    //解析extra的jason字符串
    NSString *jsonString = [object objectForKey:@"extra"];
    if (jsonString != nil) {
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        extra_dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                            options:NSJSONReadingMutableContainers
                                                              error:&err];
        NSLog(@"转换后的extra：%@",extra_dic);
        type = [extra_dic objectForKey:@"type"];
        if(err) {
            NSLog(@"extra解析失败：%@",err);
        }
    }
    
    NSString* alertStr = nil;
    if (callbackId) {
        NSLog(@"%@",callbackId);
    }
    alertStr = [[object objectForKey:@"aps"]objectForKey:@"alert"];
    //下线通知：你的账号已在别处登陆，如不是本人操作，请确认此消息
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive && [[extra_dic objectForKey:@"type"] isEqualToString:@"promit"] && alertStr != nil){
        [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
        UIAlertView*alertView = [[UIAlertView alloc]initWithTitle:@"下线通知" message:alertStr delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"重新登陆", nil];
        alertView.tag = 0;
        [alertView show];
        
    }else{
        //点击状态栏上的通知
//        dispatch_async(dispatch_get_main_queue(), ^{
//            
//        });
        [UIApplication sharedApplication].applicationIconBadgeNumber -=1;
        
        //如果点击的是下线通知
        if ([[extra_dic objectForKey:@"type"] isEqualToString:@"promit"]) {
            UIAlertView*alertView = [[UIAlertView alloc]initWithTitle:@"下线通知" message:alertStr delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"重新登陆", nil];
            alertView.tag = 1;
            [alertView show];
        }else{
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                UIAlertView*alertView = [[UIAlertView alloc]initWithTitle:@"最新资讯" message:alertStr delegate:self cancelButtonTitle:@"忽略" otherButtonTitles:@"查看", nil];
                alertView.tag = 2;
                [alertView show];
            }else{
                NSMutableDictionary *pushClick = [NSMutableDictionary dictionary];
                NSString *classType = [extra_dic objectForKey:@"classtype"];
                NSString *detailId = [extra_dic objectForKey:@"id"];
                [UIApplication sharedApplication].applicationIconBadgeNumber -=1;
                [pushClick setValue:@"notifyclick" forKey:@"type"];
                [pushClick setValue:classType forKey:@"classType"];
                [pushClick setValue:detailId forKey:@"detailId"];
                
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:pushClick options:NSJSONWritingPrettyPrinted error:nil];
                NSString *stringClick = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [self successWithMessage:[NSString stringWithFormat:@"%@",stringClick]];
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    //下线通知alert的tag值为0或者1
    if (alertView.tag == 0 || alertView.tag ==1) {
        NSLog(@"buttonIndex:%ld", (long)buttonIndex);
        //重新登陆
        if (buttonIndex == 1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                
                NSMutableDictionary *reloginClick = [NSMutableDictionary dictionary];
                [UIApplication sharedApplication].applicationIconBadgeNumber -=1;
                [reloginClick setValue:@"relogin" forKey:@"type"];
                NSLog(@"reloginClick:%@",reloginClick);
                NSData *jsonData = [NSJSONSerialization dataWithJSONObject:reloginClick options:NSJSONWritingPrettyPrinted error:nil];
                NSString *stringClick = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                [self successWithMessage:[NSString stringWithFormat:@"%@",stringClick]];
            });
        }else{
            //退出
            NSMutableDictionary *exitClick = [NSMutableDictionary dictionary];
            [UIApplication sharedApplication].applicationIconBadgeNumber -=1;
            [exitClick setValue:@"exit" forKey:@"type"];
            NSLog(@"exitClick:%@",exitClick);
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:exitClick options:NSJSONWritingPrettyPrinted error:nil];
            NSString *stringClick = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [self successWithMessage:[NSString stringWithFormat:@"%@",stringClick]];
        }
    }
    if (alertView.tag == 2) {
        if (buttonIndex == 1) {
            NSMutableDictionary *pushClick = [NSMutableDictionary dictionary];
            NSString *classType = [extra_dic objectForKey:@"classtype"];
            NSString *detailId = [extra_dic objectForKey:@"id"];
            [UIApplication sharedApplication].applicationIconBadgeNumber -=1;
            [pushClick setValue:@"notifyclick" forKey:@"type"];
            [pushClick setValue:classType forKey:@"classType"];
            [pushClick setValue:detailId forKey:@"detailId"];
            
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:pushClick options:NSJSONWritingPrettyPrinted error:nil];
            NSString *stringClick = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            [self successWithMessage:[NSString stringWithFormat:@"%@",stringClick]];
        }
        
    }
    
}
//注销推送
- (void)unregistePush:(CDVInvokedUrlCommand*)command;
{
	self.callbackId = command.callbackId;

    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [self successWithMessage:@"unregistered"];
}

/**
 *  注册推送
 *
 *  @param command 注册推送并将结果返回给js
 */
- (void)registePush:(CDVInvokedUrlCommand*)command;
{
    
    self.callbackId = command.callbackId;
	NSLog(@"%@",callbackId);
    NSUserDefaults *userDefault=[NSUserDefaults standardUserDefaults];
    NSData *token=[userDefault objectForKey:@"deviceToken"];
    NSLog(@"%@",token);
    
    NSLog(@"is registing push from ixintui");
    NSString *plistPath = [[NSBundle mainBundle]pathForResource:@"PushConfig" ofType:@"plist"];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    NSString *iappKey = [data objectForKey:@"AppKey"];
    NSString *isecretKey = [data objectForKey:@"SecretKey"];
    NSLog(@"%@,%@",iappKey,isecretKey);
    IXTNotification *ixtNotification = [[IXTNotification alloc] init: (iappKey).intValue andToken:token delegate:nil];
    //delegate是http的回调,可参照HttpDelegate.h实现
    BOOL flag = [ixtNotification register:isecretKey flag:true];
    NSString *pushToken = [[[[token description]
                             
                             stringByReplacingOccurrencesOfString:@"<" withString:@""]
                            
                            stringByReplacingOccurrencesOfString:@">" withString:@""]
                           
                           stringByReplacingOccurrencesOfString:@" " withString:@""] ;
    NSLog(@"%@:%d",pushToken,flag);
    NSString *mac = [self performSelector:@selector(getMacAddress) withObject:0];
    NSMutableDictionary *resultToken = [NSMutableDictionary dictionary];
    [resultToken setValue:@"token" forKey:@"type"];
    [resultToken setValue:pushToken forKey:@"data"];
    [resultToken setValue:mac forKey:@"mac"];
    NSLog(@"%@", resultToken);
    
    //将字典resultToken转换成string格式，作为传递给js的值
    //NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultToken options:NSJSONWritingPrettyPrinted error:nil];
    NSString *resultString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"注册通知后返回给js的字符串：%@",resultString);
    [self successWithMessage:[NSString stringWithFormat:@"%@",resultString]];
}

-(void)successWithMessage:(NSString *)message
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    [commandResult setKeepCallbackAsBool:TRUE];
    
    [self.commandDelegate sendPluginResult:commandResult callbackId:self.callbackId];
}

-(void)failWithMessage:(NSString *)message withError:(NSError *)error
{
    NSString        *errorMessage = (error) ? [NSString stringWithFormat:@"%@ - %@", message, [error localizedDescription]] : message;
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errorMessage];
    
    [self.commandDelegate sendPluginResult:commandResult callbackId:self.callbackId];
}

//获取本机mac地址，并返回mac值
- (NSString *)getMacAddress
{
    int                 mgmtInfoBase[6];
    char                *msgBuffer = NULL;
    size_t              length;
    unsigned char       macAddress[6];
    struct if_msghdr    *interfaceMsgStruct;
    struct sockaddr_dl  *socketStruct;
    NSString            *errorFlag = NULL;
    
    // Setup the management Information Base (mib)
    mgmtInfoBase[0] = CTL_NET;        // Request network subsystem
    mgmtInfoBase[1] = AF_ROUTE;       // Routing table info
    mgmtInfoBase[2] = 0;
    mgmtInfoBase[3] = AF_LINK;        // Request link layer information
    mgmtInfoBase[4] = NET_RT_IFLIST;  // Request all configured interfaces
    
    // With all configured interfaces requested, get handle index
    if ((mgmtInfoBase[5] = if_nametoindex("en0")) == 0)
    errorFlag = @"if_nametoindex failure";
    else
    {
        // Get the size of the data available (store in len)
        if (sysctl(mgmtInfoBase, 6, NULL, &length, NULL, 0) < 0)
        errorFlag = @"sysctl mgmtInfoBase failure";
        else
        {
            // Alloc memory based on above call
            if ((msgBuffer = malloc(length)) == NULL)
            errorFlag = @"buffer allocation failure";
            else
            {
                // Get system information, store in buffer
                if (sysctl(mgmtInfoBase, 6, msgBuffer, &length, NULL, 0) < 0)
                errorFlag = @"sysctl msgBuffer failure";
            }
        }
    }
    
    // Befor going any further...
    if (errorFlag != NULL)
    {
        NSLog(@"Error: %@", errorFlag);
        return errorFlag;
    }
    
    // Map msgbuffer to interface message structure
    interfaceMsgStruct = (struct if_msghdr *) msgBuffer;
    
    // Map to link-level socket structure
    socketStruct = (struct sockaddr_dl *) (interfaceMsgStruct + 1);
    
    // Copy link layer address data in socket structure to an array
    memcpy(&macAddress, socketStruct->sdl_data + socketStruct->sdl_nlen, 6);
    
    // Read from char array into a string object, into traditional Mac address format
    NSString *macAddressString = [NSString stringWithFormat:@"%02x:%02x:%02x:%02x:%02x:%02x",
                                  macAddress[0], macAddress[1], macAddress[2],
                                  macAddress[3], macAddress[4], macAddress[5]];
    // NSLog(@"Mac Address: %@", macAddressString);
    // Release the buffer memory
    free(msgBuffer);
    
    return macAddressString;
}

- (void)dealloc{
    //移除指定的通知，不然会造成内存泄露
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"iPushPluginReceiveNotificaiton" object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

