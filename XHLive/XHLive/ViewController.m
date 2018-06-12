//
//  ViewController.m
//  XHLive
//
//  Created by Michael on 2017/11/29.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import "ViewController.h"
#import <XHWaWaJi/XHWaWaJi.h>
//#import "XHWaWaJi.h"

@interface ViewController ()<XHPlayerManagerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *switchBtn;
@property (weak, nonatomic) IBOutlet UIButton *upBtn;
@property (weak, nonatomic) IBOutlet UIButton *downBtn;
@property (weak, nonatomic) IBOutlet UIButton *quitBtn;
@property (weak, nonatomic) IBOutlet UIButton *queueBtn;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UIButton *cancleBtn;

@property (nonatomic, strong) NSString *userSig;

@end

NSString * const kRoomId = @"500139";

@implementation ViewController
{
    NSString *wsUrl;
    NSString *UserSig;
    NSString *UserId;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    wsUrl = @"ws://wo.t.seafarer.me:9090/play/33c8c3e302f541b1097e6b9f6529795e76ba498e";
    UserSig = @"eJxlz0FPgzAUwPE7n6Lp2UgpdjBvuDi3uWkmDGEXgrRjFYFaCowYv7uKGpvY6*--3kvfDAAADNb*eZpldVupRA2CQXAJIIJnfygEp0mqElvSf8hOgkuWpAfF5IgWIQQjpDecskrxA-8tNGpokYz7v*Xic5AgZ2rrCc9H3FzHs*V2ll3tqi5*Lfu1G*Sm2w7OjWxWfdEvcHvvzmvzbt9FUfhYlt7y6N36bI9jLrbhExbswbRW8yEK*pwUzQb10j8*h*ql21FPLbSTipfs5zPYxZPpBDuadkw2vK7GACOLWNhGXw8a78YHp0Bc0A__";
    UserId = @"1";
    
    [self login];
}

- (void)login{
    [[XHLiveManager sharedManager] loginWithUserId:UserId sig:UserSig success:^{
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

- (IBAction)connectWS:(UIButton *)sender {
    [self startGameWebSocket];
}

- (IBAction)startQueue:(UIButton *)sender {
    [[XHPlayerManager sharedManager] startQueue];
}

- (IBAction)startGame:(UIButton *)sender {
    [[XHPlayerManager sharedManager] startGame];
}

- (IBAction)cancelQueue:(UIButton *)sender {
    [[XHPlayerManager sharedManager] cancleQueue];
}

- (IBAction)closeWS:(UIButton *)sender {
    [[XHPlayerManager sharedManager] closeWebSocket];
}

- (void)startGameWebSocket{
    XHPlayerManager *manager = [XHPlayerManager sharedManager];
    [manager setManagerListener:self];
    [manager connectWithWebSocketURL:wsUrl success:^{
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

- (void)gameReconnect:(NSDictionary *)reconnectInfo{
    NSLog(@"game reconnect,%@",reconnectInfo);
}

- (void)gamePrepare:(NSInteger)leftTime{
    NSLog(@"game prepare,%ld",leftTime);
}

- (void)gameStarted:(NSDictionary *)data{
    NSLog(@"game started,%@",data);
}

- (void)receiveGameResult:(BOOL)success sessionId:(NSString *)sessionId{
    NSLog(@"game result %@",sessionId);
}

- (void)gameWaitRestart:(NSInteger)leftTime{
    NSLog(@"game wait restart,%ld",leftTime);
}

- (void)gameError:(NSDictionary *)info errorType:(XHPlayerGameError)type{
    NSLog(@"game errofr %@",info);
}

- (void)gameQueueInfo:(NSInteger)position{
    NSLog(@"game queue info %ld",position);
}

- (void)gameQueueKickOff{
    NSLog(@"game queue Kick Off");
}

- (void)websocketClosed{
    NSLog(@"游戏结束,websocket关闭");
}

@end

