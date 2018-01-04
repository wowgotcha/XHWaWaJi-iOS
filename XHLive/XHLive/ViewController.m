//
//  ViewController.m
//  XHLive
//
//  Created by Michael on 2017/11/29.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import "ViewController.h"
#import <XHWaWaJi/XHWaWaJi.h>

@interface ViewController ()<XHPlayerManagerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *switchBtn;
@property (weak, nonatomic) IBOutlet UIButton *upBtn;
@property (weak, nonatomic) IBOutlet UIButton *downBtn;
@property (weak, nonatomic) IBOutlet UIButton *quitBtn;

@property (nonatomic, strong) NSString *userSig;

@end

NSString * const kRoomId = <#roomID#>;

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self login];
}

- (void)login{
    NSString *sig = <#userSig#>;
    
    [[XHLiveManager sharedManager] loginWithUserId:<#userId#> sig:sig success:^{
        NSLog(@"登录成功");
        [self join];
    } failure:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"登录失败");
    }];
}

- (void)join{
    NSString *masterId = [NSString stringWithFormat:@"wowgotcha_%@_1",kRoomId];
    NSString *slaveId = [NSString stringWithFormat:@"wowgotcha_%@_2",kRoomId];
    XHLiveCamera *camera = [XHLiveCamera liveCameraWithMasterId:masterId slaveId:slaveId];
    XHLiveManager *manager = [XHLiveManager sharedManager];
    [manager joinRoom:kRoomId liveCarema:camera rootView:self.view playingFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height/2, 180, 240) success:^{
        NSLog(@"加入成功");
        NSArray *renders = [manager getAllAVRenderViews];
        for (ILiveRenderView *renderView in renders) {
            renderView.autoRotate = NO;
            renderView.rotateAngle = ILIVEROTATION_90;
            renderView.backgroundColor = [UIColor blackColor];
        }
    } failure:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"加入失败");
    }];
}

- (IBAction)switchAngle:(UIButton *)sender{
    [[XHLiveManager sharedManager] switchCamera:nil];
}

- (IBAction)upToMember:(UIButton *)sender {
    [[XHLiveManager sharedManager] upToVideoMemberSuccess:^{
        NSLog(@"上麦成功");
    } failure:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"上麦失败");
    }];
}

- (IBAction)downToMember:(UIButton *)sender {
    [[XHLiveManager sharedManager] downToVideoMemberSuccess:^{
        NSLog(@"下麦成功");
    } failure:^(NSString *module, int errId, NSString *errMsg) {
        NSLog(@"下麦失败");
    }];
}

- (IBAction)quit:(UIButton *)sender {
    [[XHLiveManager sharedManager] quitRoomSuccess:^{
        NSLog(@"退出成功");
    } failure:^(NSString *vgd, int errId, NSString *errMsg) {
        NSLog(@"退出失败");
    }];
}

- (IBAction)startGame:(UIButton *)sender {
    [self startGameWebSocket];
}

- (void)startGameWebSocket{
    NSString *wsURL = @"ws://ws.open.wowgotcha.com:9090/play/5f21c3aa3badab94d35cdaa8b0f246e356fbe95f";
    XHPlayerManager *manager = [XHPlayerManager sharedManager];
    [manager setManagerListener:self];
    [manager connectWithWebSocketURL:wsURL success:^{
        NSLog(@"websocket连接成功");
    } failure:^(NSError *error) {
        NSLog(@"websocket连接失败");
    }];
}

- (IBAction)directionDown:(UIButton *)sender {
    if (sender.tag == 1000) {
        // 上
        [[XHPlayerManager sharedManager] sendOperation:XHPlayerOperationUpPress];
    }else if (sender.tag == 1001){
        // 左
        [[XHPlayerManager sharedManager] sendOperation:XHPlayerOperationLeftPress];
    }else if (sender.tag == 1002){
        // 下
        [[XHPlayerManager sharedManager] sendOperation:XHPlayerOperationDownPress];
    }else if (sender.tag == 1003){
        // 右
        [[XHPlayerManager sharedManager] sendOperation:XHPlayerOperationRightPress];
    }
}

- (IBAction)directionRelease:(UIButton *)sender {
    if (sender.tag == 1000) {
        // 上
        [[XHPlayerManager sharedManager] sendOperation:XHPlayerOperationUpRelease];
    }else if (sender.tag == 1001){
        // 左
        [[XHPlayerManager sharedManager] sendOperation:XHPlayerOperationLeftRelease];
    }else if (sender.tag == 1002){
        // 下
        [[XHPlayerManager sharedManager] sendOperation:XHPlayerOperationDownRelease];
    }else if (sender.tag == 1003){
        // 右
        [[XHPlayerManager sharedManager] sendOperation:XHPlayerOperationRightRelease];
    }
}

- (IBAction)catchAction:(UIButton *)sender {
    [[XHPlayerManager sharedManager] sendOperation:XHPlayerOperationCatch];
}

- (void)roomReady:(NSDictionary *)readyInfo{
    NSLog(@"room ready,%@",readyInfo);
}

- (void)insertCoinResult:(BOOL)result data:(NSDictionary *)data errorMsg:(NSString *)errorMsg{
    if (result) {
        // 投币成功
        NSLog(@"投币成功game session id:%@",[data objectForKey:@"game_session_id"]);
    }else{
        NSLog(@"投币失败%@",errorMsg);
    }
}

- (void)receiveGameResult:(BOOL)success sessionId:(NSString *)sessionId{
    NSLog(@"游戏结束%@",sessionId);
}

- (void)websocketClosed{
    NSLog(@"游戏结束,websocket关闭");
}

@end

