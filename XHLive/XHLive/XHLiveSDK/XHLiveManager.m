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

#import <ILiveSDK/ILiveCoreHeader.h>
#import <ILiveSDK/ILiveSDK.h>
#import <TILLiveSDK/TILLiveSDK.h>

static XHLiveManager *instance = nil;

@interface XHLiveManager ()<ILVLiveAVListener,ILVLiveIMListener>

//@property (nonatomic, strong) XHLiveCamera *liveCamera;
@property (nonatomic, strong) NSMutableArray *cameraAry;// 用户传递进来的摄像头，按主次排序
@property (nonatomic, assign) CGRect playFrame;
//@property (nonatomic, strong) NSString *currentCameraId;
@property (nonatomic, assign) NSInteger currentCameraIndex;

@property (nonatomic, assign) BOOL isEnableCamera;
@property (nonatomic, assign) CGRect userVideoFrame;
@property (nonatomic, assign) BOOL isEnableMic;

//@property (nonatomic, weak) id<XHLiveManagerListener> delegate;


@end

@implementation XHLiveManager

#pragma mark ------ 单例
+(instancetype)sharedManager{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[XHLiveManager alloc] init];
        
        instance.cameraAry = [[NSMutableArray alloc] init];
        
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
//    [self cleanOriginData];
    
    self.playFrame = frame;
    [self saveLiveCameraIds:camera];
    
    TILLiveRoomOption *option = [TILLiveRoomOption defaultGuestLiveOption]; //默认观众配置
    TILLiveManager *manager = [TILLiveManager getInstance];
    [manager setAVRootView:rootView]; //设置渲染承载的视图
    [manager joinRoom:[roomId intValue] option:option succ:^{
        [self addRendertView];// 成功加入房间，自动渲染
        [[ILiveRoomManager getInstance] setAudioMode:QAVOUTPUTMODE_SPEAKER];
        success();
    } failed:failure];
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
- (void)addRendertView{
    TILLiveManager *manager = [TILLiveManager getInstance];
    if (!self.cameraAry.count) {
        return;
    }
    for (NSInteger i = self.cameraAry.count-1; i >= 0; i--) {
        NSString *cameraId = [self.cameraAry objectAtIndex:i];
        [manager addAVRenderView:self.playFrame forIdentifier:cameraId srcType:QAVVIDEO_SRC_TYPE_CAMERA];
        
    }
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
    NSString *nextId = [self.cameraAry objectAtIndex:index];
    NSString *currentId = [self.cameraAry objectAtIndex:self.currentCameraIndex];
    [[TILLiveManager getInstance] switchAVRenderView:nextId srcType:QAVVIDEO_SRC_TYPE_CAMERA with:currentId anotherSrcType:QAVVIDEO_SRC_TYPE_CAMERA];
    self.currentCameraIndex = index;
}

#pragma mark ------ 上麦 和 下麦
- (void)upToVideoMemberSuccess:(XHSuccess)success failure:(XHFailure)failure{
    ILiveRoomManager *manager = [ILiveRoomManager getInstance];
    NSLog(@"-----%@",UserRole_LiveGuest);
    [manager changeRole:UserRole_LiveGuest succ:^{
        [self setLiveUserCameraView];
        [self setLiveMic];
        success();
    } failed:failure];
}

- (void)downToVideoMemberSuccess:(XHSuccess)success failure:(XHFailure)failure{
    ILiveRoomManager *manager = [ILiveRoomManager getInstance];
    NSLog(@"-----%@",UserRole_Guest);
//    [manager changeRole:UserRole_Guest succ:success failed:failure];
    [manager changeRole:UserRole_Guest succ:^{
        [self closeCameraAndMic];
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
    [manager quitRoom:success failed:failure];
}

#pragma mark ------ 设置视频渲染的图层
//- (void)setLiveVideoInView:(UIView *)view{
////    self.rootView = view;
//
//    TILLiveManager *manager = [TILLiveManager getInstance];
//    [manager setAVRootView:view]; //设置渲染承载的视图
//
//    NSArray *renderViews = [manager getAllAVRenderViews];
//    for (int i = 0; i < renderViews.count; i++) {
//        ILiveRenderView *renderView = renderViews[i];
//        [renderView removeFromSuperview];
//    }
//
//    [self addRendertView];
//}
//
//- (void)setLiveVideoFrame:(CGRect)frame{
//    self.playFrame = frame;
//    NSArray *arrau = [[TILLiveManager getInstance] getAllAVRenderViews];
//    for (ILiveRenderView *renderView in arrau) {
//        NSLog(@"%@",renderView.identifier);
//        if ([self.cameraAry containsObject:renderView.identifier]) {
//            // 主播renderview
//            renderView.frame = self.playFrame;
//        }
//    }
//}

//- (void)setPlayingUserVideoInView:(UIView *)view{
//    self.userVideoView = view;
//
//    TILLiveManager *manager = [TILLiveManager getInstance];
//    ILiveRenderView *renderView = [manager addAVRenderView:self.userVideoView.bounds forIdentifier:[[ILiveLoginManager getInstance] getLoginId] srcType:QAVVIDEO_SRC_TYPE_CAMERA];
//    renderView.frame = self.userVideoView.bounds;
//}

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

#pragma mark ------ 设置manager代理
//- (void)setManagerListener:(id<XHLiveManagerListener>)listener{
//    self.delegate = listener;
//}

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

