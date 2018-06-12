//
//  XHPlayerManager.m
//  XHLive
//
//  Created by Michael on 2018/1/2.
//  Copyright © 2018年 Michael. All rights reserved.
//

#import "XHPlayerManager.h"
#import "XHConst.h"
#import "GameSocketManager.h"
#import "XHLiveManager.h"
#import "XHMacro.h"

typedef NS_ENUM(NSInteger, XHPlayerCameraDirection){
    XHPlayerCameraDirectionFront,
    XHPlayerCameraDirectionSide
};

typedef NS_ENUM(NSInteger, XHPlayerGameStatus){
    XHPlayerGameStatusNone,
    XHPlayerGameStatusConnected,
    XHPlayerGameStatusReady,
    XHPlayerGameStatusQueueing,
    XHPlayerGameStatusPrepare,
    XHPlayerGameStatusPlaying,
    XHPlayerGameStatusCheckResult,
    XHPlayerGameStatusOver
};

static XHPlayerManager *instance = nil;

@interface XHPlayerManager ()
@property (strong, nonatomic) GameSocketManager *wsManger;

@property (nonatomic, weak) id<XHPlayerManagerDelegate> delegate;
@property (nonatomic, assign) XHPlayerCameraDirection cameraDirection;

@property (nonatomic, strong) NSString *insertCoinsId;
@property (nonatomic, strong) NSString *queuingId;
@property (nonatomic, strong) NSString *cancleQueueId;
@property (nonatomic, strong) NSString *closeId;

// 游戏状态
@property (nonatomic, assign) XHPlayerGameStatus gameStatu;

@end

@implementation XHPlayerManager

+(instancetype)sharedManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XHPlayerManager alloc] init];
        
        instance.insertCoinsId = @"";
        instance.enqueue = YES;
    });
    return instance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
        instance.wsManger = [[GameSocketManager alloc] init];
    });
    return instance;
}

#pragma mark ------ 设置监听代理对象
- (void)setManagerListener:(id)listener{
    self.delegate = listener;
}

- (void)connectWithWebSocketURL:(NSString *)websocketURL success:(void(^)(void))success failure:(void(^)(NSError *error))failure{
    // 开始监听摄像头的主侧信息
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateCameraDirection:) name:XHNotification_CameraIndex object:nil];
    // 监听退出房间
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userQuitRoom:) name:XHNotification_QuitRoom object:nil];
    
    // 获取当前摄像头位置
    self.cameraDirection = [[XHLiveManager sharedManager] getCameraIndex];
    
    [self.wsManger openWithURL:websocketURL connect:^{
        if (success) {
            success();
        }
        MKLog(@"web socket连接成功", nil);
    } receive:^(NSDictionary *response) {
        MKLog([NSString stringWithFormat:@"web socket接收的报文%@",response], nil);
        if (!self.delegate) {
            return;
        }
        
        // ------- 处理服务端主动消息 -------
        NSNumber *errorCode = [response valueForKey:@"errcode"];
        if (errorCode) {
            [self handleErrorMessage:response];
        }
        
        NSString *method = [response valueForKey:@"method"];
        if (method) {
            [self handleActiveMessage:response];
        }
        
        // ------- 处理服务端被动消息 -------
        NSString *operationId = [response valueForKey:@"id"];
        if (operationId) {
            [self handlePassiveMessage:response];
        }
    } failure:^(NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
}

#pragma mark ------ 消息处理
// 处理主动消息
- (void)handleActiveMessage:(NSDictionary *)message{
    NSString *method = [message valueForKey:@"method"];
    if ([method isEqualToString:SocketReceiveMsgMethodRoomReady]) {
        // 等待游戏开始
        self.gameStatu = XHPlayerGameStatusReady;
        if ([self.delegate respondsToSelector:@selector(roomReady:)]) {
            [self.delegate roomReady:[message objectForKey:@"params"]];
        }
        if (!self.enqueue) {
            if ([self.delegate respondsToSelector:@selector(gamePrepare:)]) {
                [self.delegate gamePrepare:0];
            }
        }
    }else if ([method isEqualToString:SocketReceiveMsgMethodReconect]){
        MKLog(@"web socket上局断开现在重连", nil);
        self.gameStatu = XHPlayerGameStatusPlaying;
        if ([self.delegate respondsToSelector:@selector(gameReconnect:)]) {
            [self.delegate gameReconnect:[message objectForKey:@"params"]];
        }
    }else if ([method isEqualToString:SocketReceiveMsgMethodError]){
        MKLog(@"web socket游戏异常", nil);
        if ([self.delegate respondsToSelector:@selector(gameError:errorType:)]) {
            [self.delegate gameError:message errorType:XHPlayerGameErrorOther];
        }
    }else if ([method isEqualToString:SocketReceiveMsgMethodGameReady]){
        MKLog(@"web socket排队完成，准备游戏", nil);
        NSNumber *leftTime = [[message objectForKey:@"params"] objectForKey:@"time_left"];
        if (self.gameStatu != XHPlayerGameStatusCheckResult) {
            self.gameStatu = XHPlayerGameStatusPrepare;
            if ([self.delegate respondsToSelector:@selector(gamePrepare:)]) {
                [self.delegate gamePrepare:[leftTime integerValue]];
            }
        }else{
            if ([self.delegate respondsToSelector:@selector(gameWaitRestart:)]) {
                [self.delegate gameWaitRestart:[leftTime integerValue]];
            }
        }
    }else if ([method isEqualToString:SocketReceiveMsgMethodQueueKickOff]){
        MKLog(@"web socket踢出队列", nil);
        self.gameStatu = XHPlayerGameStatusOver;
        if ([self.delegate respondsToSelector:@selector(gameQueueKickOff)]) {
            [self.delegate gameQueueKickOff];
        }
    }else if ([method isEqualToString:SocketReceiveMsgMethodQueueStatus]){
        MKLog(@"web socket队列信息", nil);
        self.gameStatu = XHPlayerGameStatusQueueing;
        NSInteger position = 0;
        NSDictionary *result = [message objectForKey:@"params"];
        NSNumber *roomStatus = [result objectForKey:@"room_status"];
        NSNumber *roomPosition = [result objectForKey:@"position"];
        if ([roomStatus integerValue] == 1) {
            position = [roomPosition integerValue] - 1;
        }else{
            position = [roomPosition integerValue];
        }
        if ([self.delegate respondsToSelector:@selector(gameQueueInfo:)]) {
            [self.delegate gameQueueInfo:position];
        }
    }else if ([method isEqualToString:SocketReceiveMsgMethodResult]){
        // 游戏结束
        // 发送关闭命令
        self.gameStatu = XHPlayerGameStatusCheckResult;
        //  处理游戏结果
        if ([self.delegate respondsToSelector:@selector(receiveGameResult:sessionId:)]) {
            NSDictionary *result = [message objectForKey:@"params"];
            NSNumber *success = [result objectForKey:@"is_catch"];
            NSNumber *sessionId = [result objectForKey:@"game_session_id"];
            if ([success integerValue]) {
                [self.delegate receiveGameResult:YES sessionId:[sessionId stringValue]];
            }else{
                [self.delegate receiveGameResult:NO sessionId:[sessionId stringValue]];
            }
        }
//        if (!self.enqueue) {
//            self.closeId = [self.wsManger sendMessage:nil method:SocketSendMsgMethodClose];
//        }
    }
}

// 处理被动消息
- (void)handlePassiveMessage:(NSDictionary *)message{
    NSString *operationId = [message valueForKey:@"id"];
    if ([operationId isEqualToString:self.insertCoinsId]) {
        // 投币响应
        if (![self.delegate respondsToSelector:@selector(gameStarted:)]) {
            return;
        }
        [self.delegate gameStarted:[message objectForKey:@"data"]];
    }else if([operationId isEqualToString:self.cancleQueueId]){
        if (![self.delegate respondsToSelector:@selector(queueCanceled)]) {
            return;
        }
        [self.delegate queueCanceled];
    }else if([operationId isEqualToString:self.closeId]){
        [self websocketClosed];
    }
}

- (void)websocketClosed{
    [self.wsManger closeConnect];
    [self resetOperationId];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:XHNotification_CameraIndex object:nil];
    if ([self.delegate respondsToSelector:@selector(websocketClosed)]) {
        [self.delegate websocketClosed];
    }
}

- (void)resetOperationId{
    self.closeId = @"0";
    self.insertCoinsId = @"0";
    self.queuingId = @"0";
    self.cancleQueueId = @"0";
}

// 处理错误信息
- (void)handleErrorMessage:(NSDictionary *)message{
    NSString *operationId = [message valueForKey:@"id"];
    if (![self.delegate respondsToSelector:@selector(gameError:errorType:)]) {
        return;
    }
    if([operationId isEqualToString:self.insertCoinsId]){
        self.gameStatu = XHPlayerGameStatusOver;
//        self.closeId = [self.wsManger sendMessage:nil method:SocketSendMsgMethodClose];
        [self.delegate gameError:message errorType:XHPlayerGameErrorInsertCoin];
    }else if ([operationId isEqualToString:self.queuingId]){
        self.gameStatu = XHPlayerGameStatusOver;
//        self.closeId = [self.wsManger sendMessage:nil method:SocketSendMsgMethodClose];
        [self.delegate gameError:message errorType:XHPlayerGameErrorQueuing];
    }else if ([operationId isEqualToString:self.cancleQueueId]){
        [self.delegate gameError:message errorType:XHPlayerGameErrorCancleQueuing];
    }else{
        MKLog(@"websocke游戏出错", message, nil);
        [self.delegate gameError:message errorType:XHPlayerGameErrorOther];
    }
}

#pragma mark ------ 开始和排队
- (void)startGame{
    self.insertCoinsId = [self.wsManger sendMessage:nil method:SocketSendMsgMethodInsertCoins];
}

- (void)startQueue{
    if (self.enqueue) {
        self.gameStatu = XHPlayerGameStatusQueueing;
        self.queuingId = [self.wsManger sendMessage:nil method:SocketSendMsgMethodStartQueue];
    }
}

- (void)cancleQueue{
    if (self.enqueue) {
        self.cancleQueueId = [self.wsManger sendMessage:nil method:SocketSendMsgMethodCancleQueue];
    }
}

#pragma mark ------ 关闭websocket
- (void)closeWebSocket{
    self.closeId = [self.wsManger sendMessage:nil method:SocketSendMsgMethodClose];
}

#pragma mark ------ 发送操作
- (void)sendOperation:(XHPlayerOperation)operation{
    NSString *command = @"";
    if (self.cameraDirection == XHPlayerCameraDirectionFront) {
        switch (operation) {
            case XHPlayerOperationUpPress:
                command = @"u";
                break;
            case XHPlayerOperationUpRelease:
                command = @"ur";
                break;
            case XHPlayerOperationLeftPress:
                command = @"l";
                break;
            case XHPlayerOperationLeftRelease:
                command = @"lr";
                break;
            case XHPlayerOperationDownPress:
                command = @"d";
                break;
            case XHPlayerOperationDownRelease:
                command = @"dr";
                break;
            case XHPlayerOperationRightPress:
                command = @"r";
                break;
            case XHPlayerOperationRightRelease:
                command = @"rr";
                break;
            case XHPlayerOperationCatch:
                command = @"g";
                break;
        }
    }else{
        switch (operation) {
            case XHPlayerOperationUpPress:
                command = @"l";
                break;
            case XHPlayerOperationUpRelease:
                command = @"lr";
                break;
            case XHPlayerOperationLeftPress:
                command = @"d";
                break;
            case XHPlayerOperationLeftRelease:
                command = @"dr";
                break;
            case XHPlayerOperationDownPress:
                command = @"r";
                break;
            case XHPlayerOperationDownRelease:
                command = @"rr";
                break;
            case XHPlayerOperationRightPress:
                command = @"u";
                break;
            case XHPlayerOperationRightRelease:
                command = @"ur";
                break;
            case XHPlayerOperationCatch:
                command = @"g";
                break;
        }
    }
    // 发送操作指令
    [self.wsManger sendMessage:@{@"operation":command} method:SocketSendMsgMethodControl];
    
}

#pragma mark ------ 事件监听
// 获取当前摄像头的方向
- (void)updateCameraDirection:(NSNotification *)noti{
    NSNumber *index = (NSNumber *)[noti object];
    self.cameraDirection = [index integerValue];
}

- (void)userQuitRoom:(NSNotification *)noti{
    if (self.wsManger) {
        [self.wsManger closeConnect];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:XHNotification_QuitRoom object:nil];
}

#pragma mark ------ getter

@end
