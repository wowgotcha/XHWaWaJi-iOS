//
//  ViewController.m
//  XHLive
//
//  Created by Michael on 2017/11/29.
//  Copyright © 2017年 Michael. All rights reserved.
//

#import "ViewController.h"
#import <XHWaWaJi/XHLiveManager.h>


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *switchBtn;
@property (weak, nonatomic) IBOutlet UIButton *upBtn;
@property (weak, nonatomic) IBOutlet UIButton *downBtn;
@property (weak, nonatomic) IBOutlet UIButton *quitBtn;

@property (nonatomic, strong) NSString *userSig;

@end

NSString * const kRoomId = @"500001";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self login];
}

- (void)login{
    NSString *sig=  @"eJxlj11LwzAUhu-7K0JuJ5KmjbaCF11XRVgn0q6iN6EuZ1v8SGOWTrPhf3dWxYDv7fOc8-LuA4QQrqfVcbtYdL2y3DoNGJ0hTPDRH9RaCt5aHhnxD8K7lgZ4u7RgBhgyxighviMFKCuX8tfw0EY88eH-N4kPh4ycppGvyNUAy2KeX2V58*xotKMP*WV2zbokedQXt03HqtGdie1kfDNfT0ifKNhlssh6VqspLWcJnaXgqHobwep1XbptUTWhFmKcuvtS1rmG4tyrtPIFfsaEcUxPQubP2YLZyE4NAiUHhUbkKzj4CD4BqwFauw__";
    [[XHLiveManager sharedManager] loginWithUserId:@"1" sig:sig success:^{
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

@end
