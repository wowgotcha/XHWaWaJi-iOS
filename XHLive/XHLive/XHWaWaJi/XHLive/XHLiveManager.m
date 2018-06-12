//
//  XHLiveManager.m
//  XHLive
//
//  Created by Michael on 2017/11/29.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import "XHLiveManager.h"

#import "XHMacro.h"
#import "XHConst.h"

#import <MediaPlayer/MediaPlayer.h>

static XHLiveManager *instance = nil;

@interface XHLiveManager ()<ILVLiveAVListener,ILVLiveIMListener>

// 基本属性
@property (nonatomic, strong) NSString *roomId;// 当前房间id
@property (nonatomic, strong) NSMutableArray *cameraAry;// 用户传递进来的摄像头，按主次排序
@property (nonatomic, strong) UIView *rootView;// 所有frame依赖的父视图
@property (nonatomic, assign) CGRect playFrame;// 游戏视频frame
@property (nonatomic, assign) NSInteger currentCameraIndex;// 当前摄像头方位，0=>正，1=>侧
@property (nonatomic, assign) BOOL isInRoom;// 是否加入房间
@property (nonatomic, strong) NSMutableArray *renderViews;// 主侧摄像头的渲染视图数组

// 玩家相关
@property (nonatomic, assign) BOOL isEnableCamera;// 是否开启摄像头
@property (nonatomic, assign) CGRect userVideoFrame;// 用户摄像头视频frame
@property (nonatomic, assign) BOOL isEnableMic;// 是否开启麦克风


@end

@implementation XHLiveManager

#pragma mark ------ 单例
+(instancetype)sharedManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XHLiveManager alloc] init];
        
        instance.cameraAry = [[NSMutableArray alloc] init];
        instance.renderViews = [[NSMutableArray alloc] init];
        instance.roomId = @"";
    });
    return instance;
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [super allocWithZone:zone];
    });
    return instance;
}

#pragma mark ------ 初始化
- (void)initSdk:(int)appId accountType:(int)accountType{
    [[ILiveSDK getInstance] initSdk:appId accountType:accountType];
}

#pragma mark ------ 登录
- (void)loginWithUserId:(NSString *)userId sig:(NSString *)sig success:(XHSuccess)success failure:(XHFailure)failure{
    // 设置代理
    TILLiveManager *manager = [TILLiveManager getInstance];
    [manager setAVListener:self];
    [manager setIMListener:self];
    [[ILiveLoginManager getInstance] iLiveLogin:userId sig:sig succ:success failed:failure];
}

#pragma mark ------ 加入房间
- (void)joinRoom:(NSString *)roomId liveCarema:(XHLiveCamera *)camera rootView:(UIView *)rootView playingFrame:(CGRect)frame success:(XHSuccess)success failure:(XHFailure)failure{
    self.roomId = roomId;
    self.rootView = rootView;
    self.playFrame = frame;
    [self saveLiveCameraIds:camera];
    
    TILLiveRoomOption *option = [TILLiveRoomOption defaultGuestLiveOption]; //默认观众配置
    TILLiveManager *manager = [TILLiveManager getInstance];
    [manager setAVRootView:rootView]; //设置渲染承载的视图
    [manager joinRoom:[roomId intValue] option:option succ:^{
        self.renderViews = [[self addRendertView] mutableCopy];// 成功加入房间，自动渲染
        self.isInRoom = YES;
        [self setSystemVolumeNormal];
        [[NSNotificationCenter defaultCenter] postNotificationName:XHNotification_CameraIndex object:[NSNumber numberWithInteger:self.currentCameraIndex]];
        success();
    } failed:failure];
    
    
    [[ILiveRoomManager getInstance] enableMic:NO succ:nil failed:nil];
}
- (void)getVideoQuality{
    ILiveQualityData *qualituy = [[ILiveRoomManager getInstance] getQualityData];
//    MWLog(@"----------------丢包率**  %ld",qualituy.recvLossRate);
//    MWLog(@"----------------接收速率**  %ld",qualituy.recvRate);
//    MWLog(@"----------------画面帧率**  %ld",qualituy.interactiveSceneFPS);
}

- (void)cleanOriginData{
    self.cameraAry = nil;
//    self.rootView = nil;
//    self.userVideoView = nil;
}

- (void)saveLiveCameraIds:(XHLiveCamera *)camera{
    if (!self.cameraAry) {
        self.cameraAry = [[NSMutableArray alloc] init];
    }
    if (self.cameraAry.count) {
        [self.cameraAry removeAllObjects];
    }

    // 按主次数序添加摄像头id
    if (camera.masterId.length) {
        [self.cameraAry addObject:camera.masterId];
    }
    if (camera.slaveId.length) {
        [self.cameraAry addObject:camera.slaveId];
    }
}

// 渲染主播摄像头renderview
- (NSArray *)addRendertView{
    TILLiveManager *manager = [TILLiveManager getInstance];
    if (!self.cameraAry.count) { return nil; }
//    if (self.renderViews.count) { [self.renderViews removeAllObjects]; }
    NSMutableArray *renderViewAry = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < self.cameraAry.count; i++) {
        NSString *cameraId = [self.cameraAry objectAtIndex:i];
        ILiveRenderView *renderView = [manager addAVRenderView:self.playFrame forIdentifier:cameraId srcType:QAVVIDEO_SRC_TYPE_CAMERA];
        renderView.autoRotate = NO;
        renderView.rotateAngle = ILIVEROTATION_90;
        renderView.backgroundColor = self.rootView.backgroundColor;
        renderView.hidden = YES;
        if (i == 0) {
            renderView.hidden = NO;
        }
        [renderViewAry addObject:renderView];
        [[TILLiveManager getInstance] bringAVRenderViewToFront:cameraId srcType:QAVVIDEO_SRC_TYPE_CAMERA];
    }
    return renderViewAry;
}

#pragma mark ------ 切换摄像头
- (void)switchCamera:(NSString *)cameraId{
    if (!self.cameraAry.count) {
        return;
    }
    
    NSInteger nextIndex = 0;
    if (cameraId.length) {
        NSInteger index = [self.cameraAry indexOfObject:cameraId];
        if (index == NSNotFound) {
            return;
        }
        nextIndex = index;
    }else{
        nextIndex = [self getNextCameraIndex];
    }
    [self switchCameraIndex:nextIndex];
}

// 获取下一个摄像头的index
- (NSInteger)getNextCameraIndex{
    NSInteger nextIndex = 0;
    if (self.currentCameraIndex < self.cameraAry.count-1) {
        nextIndex = self.currentCameraIndex + 1;
    }
    return nextIndex;
}

// 根据index来切换摄像头，并更新self.currentCameraIndex
- (void)switchCameraIndex:(NSInteger)index{
//    NSString *nextId = [self.cameraAry objectAtIndex:index];
//    NSString *currentId = [self.cameraAry objectAtIndex:self.currentCameraIndex];
//    [[TILLiveManager getInstance] switchAVRenderView:nextId srcType:QAVVIDEO_SRC_TYPE_CAMERA with:currentId anotherSrcType:QAVVIDEO_SRC_TYPE_CAMERA];
    
//    NSArray *renders = [[TILLiveManager getInstance] getAllAVRenderViews];
//    NSLog(@"当前显示的index%ld，cameraid是：%@",self.currentCameraIndex, self.cameraAry[self.currentCameraIndex]);
    for (ILiveRenderView *render in self.renderViews) {
        render.hidden = YES;
    }
    self.currentCameraIndex = index;
    ILiveRenderView *nextRender = self.renderViews[self.currentCameraIndex];
    nextRender.hidden = NO;
//    NSLog(@"切换后显示的index%ld，cameraid是：%@，%@",self.currentCameraIndex, self.cameraAry[self.currentCameraIndex],nextRender.identifier);
    [[NSNotificationCenter defaultCenter] postNotificationName:XHNotification_CameraIndex object:[NSNumber numberWithInteger:self.currentCameraIndex]];
}

#pragma mark ------ 上麦 和 下麦
- (void)upToVideoMemberSuccess:(XHSuccess)success failure:(XHFailure)failure{
    ILiveRoomManager *manager = [ILiveRoomManager getInstance];
    [manager changeRole:UserRole_LiveGuest succ:^{
        [self setLiveUserCameraView];
        [self setLiveMic];
        [self setSystemVolumeNormal];
        if (success) {
            success();
        }
    } failed:failure];
}

- (void)downToVideoMemberSuccess:(XHSuccess)success failure:(XHFailure)failure{
    ILiveRoomManager *manager = [ILiveRoomManager getInstance];
    [manager changeRole:UserRole_Guest succ:^{
        [self closeCameraAndMic];
        [self setSystemVolumeNormal];
        if (success) {
            success();
        }
    } failed:failure];
}

- (void)closeCameraAndMic{
    ILiveRoomManager *manager = [ILiveRoomManager getInstance];
    if (self.isEnableCamera) {
        [manager enableCamera:CameraPosFront enable:NO succ:nil failed:nil];
    }
    if (self.isEnableMic) {
        [manager enableMic:NO succ:nil failed:nil];
    }
    
}

#pragma mark ------ 退出房间
- (void)quitRoomSuccess:(XHSuccess)success failure:(XHFailure)failure{
    ILiveRoomManager *manager = [ILiveRoomManager getInstance];
    [manager quitRoom:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:XHNotification_QuitRoom object:nil];
        self.isInRoom = NO;
        self.currentCameraIndex = 0;
        [self setSystemVolumeNormal];
        if (success) {
            success();
        }
    } failed:failure];
}

#pragma mark ------ 重新拉流
- (void)reloadLiveStream:(XHSuccess)success failure:(XHFailure)failure{
    ILiveQualityData *quality = [[ILiveRoomManager getInstance] getQualityData];
    if (quality.recvRate > 10) {
        success();
        return;
    }
    TILLiveRoomOption *option = [TILLiveRoomOption defaultGuestLiveOption]; //默认观众配置
    TILLiveManager *manager = [TILLiveManager getInstance];
    [manager setAVRootView:self.rootView]; //设置渲染承载的视图
    [manager joinRoom:[self.roomId intValue] option:option succ:^{
        NSArray *newRenders = [self addRendertView];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                for (ILiveRenderView *renderView in self.renderViews) {
                    [renderView removeFromSuperview];
                }
                self.renderViews = [newRenders mutableCopy];
                [self switchCameraIndex:self.currentCameraIndex];
            });
        });
        self.isInRoom = YES;
        [[ILiveRoomManager getInstance] setAudioMode:QAVOUTPUTMODE_SPEAKER];
        [self setSystemVolumeNormal];
        success();
    } failed:failure];
}

#pragma mark ------ 开启摄像头和麦克风
- (void)enableCameraWithPlayerFrame:(CGRect)frame{
    self.isEnableCamera = YES;
    self.userVideoFrame = frame;
}

- (void)setLiveUserCameraView{
    if (!self.isEnableCamera) {
        return;
    }
    [[ILiveRoomManager getInstance] enableCamera:CameraPosFront enable:YES succ:^{
        NSString *loginUserId = [[ILiveLoginManager getInstance] getLoginId];
        [[TILLiveManager getInstance] addAVRenderView:self.userVideoFrame forIdentifier:loginUserId srcType:QAVVIDEO_SRC_TYPE_CAMERA];
    } failed:^(NSString *module, int errId, NSString *errMsg) {
//        if (self.delegate) {
//            if ([self.delegate respondsToSelector:@selector(enableCameraFailure:)]) {
//                [self.delegate enableCameraFailure:errMsg];
//            }
//        }
    }];
}

- (void)enableMic{
    self.isEnableMic = YES;
}

- (void)setLiveMic{
    if (!self.isEnableMic) {
        return;
    }
    [[ILiveRoomManager getInstance] enableMic:YES succ:^{
        
    } failed:^(NSString *module, int errId, NSString *errMsg) {
//        if (self.delegate) {
//            if ([self.delegate respondsToSelector:@selector(enableMicFailure:)]) {
//                [self.delegate enableMicFailure:errMsg];
//            }
//        }
    }];
    
}

#pragma mark ------ 获取所有渲染视图
- (NSArray<ILiveRenderView *> *)getAllAVRenderViews{
    return [[TILLiveManager getInstance] getAllAVRenderViews];
}

#pragma mark ------ 视频回调
- (void)onUserUpdateInfo:(ILVLiveAVEvent)event users:(NSArray *)users{
    NSLog(@"视频回调事件%@",users);
    if (event == ILVLIVE_AVEVENT_CAMERA_ON) {
        NSLog(@"%@",users);
        NSString *loginUserId = [[ILiveLoginManager getInstance] getLoginId];
        if (!self.isEnableCamera) {
            return;
        }
        for (NSString *cameraId in users) {
            if ([self.cameraAry containsObject:cameraId] ||
                [cameraId isEqualToString:loginUserId]) {
                continue;
            }
            
            [[TILLiveManager getInstance] addAVRenderView:self.userVideoFrame forIdentifier:cameraId srcType:QAVVIDEO_SRC_TYPE_CAMERA];
        }
        
    }else if (event == ILVLIVE_AVEVENT_CAMERA_OFF){
        if (!self.isEnableCamera) {
            return;
        }
        for (NSString *cameraId in users) {
            [[TILLiveManager getInstance] removeAVRenderView:cameraId srcType:QAVVIDEO_SRC_TYPE_CAMERA];
        }
    }
}

#pragma mark ------ 获取摄像头下标
- (NSInteger)getCameraIndex{
    return self.currentCameraIndex;
}

#pragma mark ------ 禁用ILiveSDK的log打印
- (BOOL)isLogPrint{
    return NO;
}
- (NSString *)getLogPath{
    return [[TIMManager sharedInstance] getLogPath];
}
- (void)disableLogPrint{
    TIMManager *manager = [[ILiveSDK getInstance] getTIMManager];
    [manager initLogSettings:NO logPath:[manager getLogPath]];
    [[ILiveSDK getInstance] setConsoleLogPrint:NO];
    [QAVAppChannelMgr setExternalLogger:self];
}

#pragma mark ------ 设置系统声音
- (void)setSystemVolumeNormal{
    [[[ILiveSDK getInstance] getAVContext].audioCtrl changeAudioCategory:2];
}

@end

@interface XHLiveCamera ()
@property (nonatomic, copy, readwrite) NSString *masterId;
@property (nonatomic, copy, readwrite) NSString *slaveId;
@end

@implementation XHLiveCamera

+ (XHLiveCamera *)liveCameraWithMasterId:(NSString *)masterId slaveId:(NSString *)slaveId{
    XHLiveCamera *camera = [[XHLiveCamera alloc] init];
    camera.masterId = masterId;
    camera.slaveId = slaveId;
    return camera;
}

@end

