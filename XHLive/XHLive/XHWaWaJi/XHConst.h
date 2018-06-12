//
//  XHConst.h
//  XHLive
//
//  Created by Michael on 2017/11/30.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XHConst : NSObject

/** 主播 */
UIKIT_EXTERN NSString *const UserRole_LiveMaster;

/** 连麦观众 */
UIKIT_EXTERN NSString *const UserRole_LiveGuest;

/** 普通观众 */
UIKIT_EXTERN NSString *const UserRole_Guest;

/** 摄像头信息（下标）通知 */
UIKIT_EXTERN NSString *const XHNotification_CameraIndex;

/** 摄像头信息（下标）通知 */
UIKIT_EXTERN NSString *const XHNotification_QuitRoom;

FOUNDATION_EXPORT void MKLog(NSString *first, ...) NS_REQUIRES_NIL_TERMINATION;

@end
