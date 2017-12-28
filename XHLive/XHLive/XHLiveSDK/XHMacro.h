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
#define DebugLog(...) NSLog(__VA_ARGS__)
#else
#define DebugLog(...)
#endif

#endif /* XHMacro_h */
