//
//  XHMacro.h
//  XHLive
//
//  Created by Michael on 2017/11/29.
//  Copyright © 2017年 Michael. All rights reserved.
//

#ifndef XHMacro_h
#define XHMacro_h

#import <UIKit/UIKit.h>

// 日志输出
#ifdef DEBUG
#define XHDebugLog(...) NSLog(__VA_ARGS__)
#else
#define XHDebugLog(...)
#endif


#define XHConfig [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"XHConfig" ofType:@"plist"]]



#endif /* XHMacro_h */
