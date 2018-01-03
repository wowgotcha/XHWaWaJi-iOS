//
//  XHPlayerManager.h
//  XHLive
//
//  Created by Michael on 2018/1/2.
//  Copyright © 2018年 Michael. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, XHPlayerOperation){
    XHPlayerOperationUpPress,
    XHPlayerOperationUpRelease,
    XHPlayerOperationLeftPress,
    XHPlayerOperationLeftRelease,
    XHPlayerOperationDownPress,
    XHPlayerOperationDownRelease,
    XHPlayerOperationRightPress,
    XHPlayerOperationRightRelease,
    XHPlayerOperationCatch
};

@protocol XHPlayerManagerDelegate<NSObject>

/**
 *  websocket连接成功，游戏进入roomReady状态
 */
- (void)roomReady:(NSDictionary *)readyInfo;

/**
 *  投币成功
 *  @param result    投币结果
 *  @param data    投币成功，会返回这个内容，否则为nil
 *  @param errorMsg    投币成功，会返回错误信息，否则为nil
 */
- (void)insertCoinResult:(BOOL)result data:(NSDictionary *)data errorMsg:(NSString *)errorMsg;

/**
 *  接收游戏抓取结果
 *  @param success    抓取结果
 *  @param sessionId    游戏记录id
 */
- (void)receiveGameResult:(BOOL)success sessionId:(NSString *)sessionId;

@optional
/**
 *  游戏结束后关闭websocket后进入该回调
 */
- (void)websocketClosed;

@end

@interface XHPlayerManager : NSObject

/**
 *  管理类单例
 */
+ (instancetype)sharedManager;

/**
 *  设置监听对象
 */
- (void)setManagerListener:(id)listener;

/**
 *  连接游戏websocket
 *
 *  @param websocketURL    游戏websocket链接
 *  @param success    连接成功回调
 *  @param failure    连接失败回调
 */
- (void)connectWithWebSocketURL:(NSString *)websocketURL success:(void(^)(void))success failure:(void(^)(NSError *error))failure;

/**
 *  发送游戏指令
 *
 *  @param operation    XHPlayerOperation枚举值，注意按下与释放必须成对发送，用户按下时发送Press结尾的枚举值，松开时发送Release结尾的枚举值
 */
- (void)sendOperation:(XHPlayerOperation)operation;

@end
