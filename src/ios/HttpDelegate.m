//
//  HttpDelegate.m
//  testPush
//
//  Created by jwt on 15/9/21.
//  Copyright (c) 2015年 wsy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HttpDelegate.h"

@interface HttpDelegate(){
    NSString *res;
}

@end
//回调的delegate实现demo，可根据自己的需求更改代码逻辑
@implementation HttpDelegate
- (instancetype)init
{
    self = [super init];
    if (self) {
        res = @"";
    }
    return self;
}
//请求错误时处理
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error{
    NSLog(@"error=%@",error);
}
//判断返回状态
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int status = [httpResponse statusCode];
    if(status == 200){
        NSLog(@"succ");
    }else{
        NSLog(@"status=%d",status);
    }
}
//触发次数 >= 1
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data{
    NSString *ret = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (ret != nil) {
        NSLog(@"retttttt=%@",ret);
        res = [res stringByAppendingString:ret];
    }else{
        NSLog(@"nodata receive");
    }
}
//数据接收完成时触发，一般在这里做具体逻辑
- (void)connectionDidFinishLoading:(NSURLConnection *)connection{
    NSLog(@"ressssss=%@",res);
}
//其它回调方法请根据自身需求参照官方api 实现
@end
