//
//  XHConst.m
//  XHLive
//
//  Created by Michael on 2017/11/30.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import "XHConst.h"
#import "XHMacro.h"

@implementation XHConst

NSString *const UserRole_LiveMaster = @"LiveMaster";

NSString *const UserRole_LiveGuest = @"LiveGuest";

NSString *const UserRole_Guest = @"Guest";

NSString *const XHNotification_CameraIndex = @"XHNotification_CameraIndex";

NSString *const XHNotification_QuitRoom = @"XHNotification_QuitRoom";

void MKLog(NSString *first, ...){
    NSNumber *isDebug = [XHConfig objectForKey:@"Debug"];
    if ([isDebug integerValue]) {
        va_list args;
        va_start(args, first);
        NSString *next;
        NSMutableString *string = [[NSMutableString alloc] initWithFormat:@"Panda: %@",first];
        while ((next = va_arg(args, NSString *))) {
            [string appendString:[NSString stringWithFormat:@"，%@", next]];
        }
        XHDebugLog(@"%@", string);
        va_end(args);
    }
}

@end
