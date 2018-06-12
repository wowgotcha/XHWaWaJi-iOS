//
//  GameSocketManager.h
//  wowgotcha
//
//  Created by Michael on 2017/12/2.
//  Copyright © 2017年 renrele. All rights reserved.
//

#import "FLSocketManager.h"

static NSString *const SocketSendMsgMethodControl = @"control"; // 操作控制
static NSString *const SocketSendMsgMethodInsertCoins = @"insert_coins"; // 投币
static NSString *const SocketSendMsgMethodStartQueue = @"start_queue"; // 排队
static NSString *const SocketSendMsgMethodCancleQueue = @"cancel_queue"; // 取消排队
static NSString *const SocketSendMsgMethodClose = @"close"; // 关闭

static NSString *const SocketReceiveMsgMethodResult = @"game_result"; // 游戏结果
static NSString *const SocketReceiveMsgMethodRoomReady = @"room_ready"; // 投币成功，等待游戏
static NSString *const SocketReceiveMsgMethodGameReady = @"game_ready"; // 投币成功，等待游戏
static NSString *const SocketReceiveMsgMethodReconect = @"game_reconnect"; // 游戏重连
static NSString *const SocketReceiveMsgMethodError = @"room_error"; // 游戏出错
static NSString *const SocketReceiveMsgMethodQueueKickOff = @"room_queue_kick_off"; // 踢出队列
static NSString *const SocketReceiveMsgMethodQueueStatus = @"room_queue_status"; // 排队状态

@interface GameSocketManager : FLSocketManager

- (void)openWithURL:(NSString *)url connect:(FLSocketDidConnectBlock)connect receive:(void (^)(NSDictionary *response))receive failure:(FLSocketDidFailBlock)failure;

- (NSString *)sendMessage:(NSDictionary *)data method:(NSString *)method;

- (void)closeConnect;

@end
