//
//  IXTNotification.h
//  testPush
//
//  Created by jwt on 15/9/21.
//  Copyright (c) 2015年 wsy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IXTNotification:NSObject {
    
}

- (id) init:(int)appkey andToken:(NSData *) token delegate:(NSObject *) delegate;
- (BOOL) register:(NSString *)secretKey flag:(BOOL) flag;
@end
