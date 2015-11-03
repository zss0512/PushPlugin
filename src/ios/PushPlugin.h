//
//  PushPlugin.h
//  ChaoGeDoor
//
//  Created by jwt on 15/10/8.
//
//

#import <Foundation/Foundation.h>
#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#define iPushPluginReceiveNotificaiton @"ixinPushPluginRecieveNotification"

@interface PushPlugin : CDVPlugin

@property (nonatomic, copy) NSString *callback;
@property (nonatomic, copy) NSString *callbackId;
@property (nonatomic, strong) NSDictionary *notificationMessage;
@property (nonatomic,strong)UIWebView *webview;
@property (nonatomic,strong)NSDictionary *extra_dic;

- (void)registePush:(CDVInvokedUrlCommand*)command;

@end
