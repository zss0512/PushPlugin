/*
 Copyright 2009-2011 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binaryform must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided withthe distribution.

 THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC``AS IS'' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "PushPlugin.h"
#import "IXTNotification.h"
#import <sys/sysctl.h>
#import <net/if.h>
#import <net/if_dl.h>

@implementation PushPlugin

@synthesize notificationMessage;
@synthesize isInline;

@synthesize callbackId;
@synthesize notificationCallbackId;
@synthesize callback;


- (void)unregister:(CDVInvokedUrlCommand*)command;
{
	self.callbackId = command.callbackId;

    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
    [self successWithMessage:@"unregistered"];
}

- (void)register:(CDVInvokedUrlCommand*)command;
{
	self.callbackId = command.callbackId;

    NSMutableDictionary* options = [command.arguments objectAtIndex:0];

    UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeNone;
    
    id badgeArg = [options objectForKey:@"badge"];
    id soundArg = [options objectForKey:@"sound"];
    id alertArg = [options objectForKey:@"alert"];
    
    if ([badgeArg isKindOfClass:[NSString class]])
    {
        if ([badgeArg isEqualToString:@"true"])
            notificationTypes |= UIRemoteNotificationTypeBadge;
    }
    else if ([badgeArg boolValue])
        notificationTypes |= UIRemoteNotificationTypeBadge;
    
    if ([soundArg isKindOfClass:[NSString class]])
    {
        if ([soundArg isEqualToString:@"true"])
            notificationTypes |= UIRemoteNotificationTypeSound;
    }
    else if ([soundArg boolValue])
        notificationTypes |= UIRemoteNotificationTypeSound;
    
    if ([alertArg isKindOfClass:[NSString class]])
    {
        if ([alertArg isEqualToString:@"true"])
            notificationTypes |= UIRemoteNotificationTypeAlert;
    }
    else if ([alertArg boolValue])
        notificationTypes |= UIRemoteNotificationTypeAlert;
    
    self.callback = [options objectForKey:@"ecb"];

    if (notificationTypes == UIRemoteNotificationTypeNone)
        NSLog(@"PushPlugin.register: Push notification type is set to none");

    isInline = NO;

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
    
	
	if (notificationMessage)			// if there is a pending startup notification
		[self notificationReceived];	// go ahead and process it
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {

    NSLog(@"is registing push from ixintui");
    NSString *plistPath = [[NSBundle mainBundle]pathForResource:@"PushConfig" ofType:@"plist"];
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    NSString *iappKey = [data objectForKey:@"AppKey"];
    NSString *isecretkey = [data objectForKey:@"SecretKey"];
    NSLog(@"%@,%@",iappKey,isecretkey);
    IXTNotification *ixtNotification = [[IXTNotification alloc] init: (iappKey).intValue andToken:deviceToken delegate:nil];
    //delegate是http的回调,可参照HttpDelegate.h实现
    BOOL flag = [ixtNotification register:isecretkey flag:true];
    NSString *pushToken = [[[[deviceToken description]
                             
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

    [self successWithMessage:[NSString stringWithFormat:@"registePush(%@)",resultString]];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [self failWithMessage:@"" withError:error];
}
//通知的点击处理
- (void)notificationReceived {
    NSLog(@"Notification received");

    if (notificationMessage && self.callback)
    {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:[notificationMessage objectForKey:@"type"]
                                                           options:0
                                                             error:&error];
        
        if (!jsonData) {
            NSLog(@"Error parsing the notification message: %@", error);
        } else {
            NSString * jsCallBack = [NSString stringWithFormat:@"%@", self.notificationMessage];
            [self.webView stringByEvaluatingJavaScriptFromString:jsCallBack];//发送jsCallBack字符串到JavaScript的并取得返回值，显示在webView
        }
        
        self.notificationMessage = nil;
    }
    else{
        NSLog(@"An error was encountered processing the notification\nNotificationMessage: %@\nCallback: %@", notificationMessage, self.callback);
    }
}

- (void)setApplicationIconBadgeNumber:(CDVInvokedUrlCommand*)command; {
  DLog(@"setApplicationIconBadgeNumber:%@\n", command.arguments);
    
    self.callbackId = command.callbackId;
    
    NSMutableDictionary* options = [command.arguments objectAtIndex:0];
    
    int badge = [[options objectForKey:@"badge"] intValue] ?: 0;
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:badge];
    
    [self successWithMessage:[NSString stringWithFormat:@"app badge count set to %d", badge]];
}

-(void)successWithMessage:(NSString *)message
{
    CDVPluginResult *commandResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:message];
    
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

@end
