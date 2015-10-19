//
//  IXTNotification.m
//  testPush
//
//  Created by jwt on 15/9/21.
//  Copyright (c) 2015年 wsy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IXTNotification.h"
#import "NSStringHelper.h"
#import "HttpDelegate.h"

@interface IXTNotification(){
    NSString *deviceToken;
    int appkey;
    NSObject *delegate;
}

@end

@implementation IXTNotification

- (instancetype) init:(int)_appkey andToken:(NSData *) token delegate:(NSObject *) _delegate{
    self = [super init];
    if (self) {
        appkey = _appkey;
        deviceToken = [[NSString stringWithFormat:@"%@",token] stringByReplacingOccurrencesOfString:@" " withString:@""];
        deviceToken = [deviceToken substringWithRange:NSMakeRange(1, 64)];
        NSLog(@"%@",deviceToken);
        if (delegate == nil) {
            delegate = [HttpDelegate new];
        }else{
            delegate = _delegate;
        }
    }
    return self;
}

- (BOOL) register:(NSString *)secretKey flag:(BOOL) flag{ //注意flag=true是添加token,flag=false是删除token
    BOOL isSucc = NO;
    
    NSString *httpUrl = @"http://iosmis.ixintui.com:8200/register";
    NSString *httpBody = [NSString stringWithFormat:@"{\"appkey\":\"%d\",\"token\":\"%@\"}%@",appkey,deviceToken,secretKey];
    httpBody = [NSString stringWithFormat:@"{\"appkey\":\"%d\",\"token\":\"%@\",\"sign\":\"%@\"}",appkey,deviceToken,httpBody.md5];
    
    isSucc = [self httpRequest:httpUrl httpBody:httpBody method:(flag ? @"POST" : @"DELETE")];
    
    return isSucc;
}

- (BOOL)httpRequest:(NSString *) httpUrl httpBody:(NSString *) httpBody method:(NSString *) method{
    NSURL *url;
    NSMutableURLRequest *request;
    url=[NSURL URLWithString:httpUrl];
    if (url == nil){
        return NO;
    }
    request=[NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method];
    [request setHTTPBody:[httpBody dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES]];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-type"];
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:request delegate:delegate startImmediately:NO];
    if(conn != nil){
        [conn start];
        NSLog(@"conn=%@",conn);
    }else{
        return NO;
    }
    return YES;
}
@end
