# XHWaWaJi 对接文档
### 一、使用前准备
下载腾讯互动直播SDK，添加到工程里，并修改工程配置和导入系统库。具体操作请参考[下载并导入Frameworks](http://open.doc.wowgotcha.com/lv/ios/frameworks.html)

> [XHLive](https://github.com/wowgotcha/XHWaWaJi-iOS) 已正常接入framework，包含[XHWaWaJi.Framework](https://github.com/wowgotcha/XHWaWaJi-iOS/tree/master/XHLive/XHLive)和腾讯互动直播SDK的[下载脚本](https://github.com/wowgotcha/XHWaWaJi-iOS/tree/master/XHLive/XHLive/TencentLiveSDK)，可以方便的找到并执行。

另外，请在Build Settings设置`Allow Non-modular Includes in Framework Modules`为Yes

### 二、接入流程
#### 初始化XHLive
##### 1. 应用启动先初始化：
    
```
[[XHLiveManager sharedManager] initSdk:TENCLOUDAPPID accountType:TENCLOUDACCOUNTTYPE];
```
    
**参数说明：**

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| TENCLOUDAPPID | int | 接入方腾讯云的appId，与 HTTP 接口使用的 appid 参数不同 |
| TENCLOUDACCOUNTTYPE | int | 腾讯云的 accountType |

##### 2. 登录视频服务
    
```
[[XHLiveManager sharedManager] loginWithUserId:@"1" sig:sig success:^{
    NSLog(@"登录成功");
} failure:^(NSString *module, int errId, NSString *errMsg) {
    NSLog(@"登录失败");
}];
```
    
 **参数说明：**
 
| 参数 | 类型 | 说明 |
| --- | --- | --- |
| userId | string | 接入方用户系统的用户id |
| TENCLOUDACCOUNTTYPE | int | 通过HTTP接口获取的用户签名信息 |

#### 进入直播间
##### 1. 设置渲染窗口frame，加入直播间

```
XHLiveCamera *camera = [XHLiveCamera liveCameraWithMasterId:masterId slaveId:slaveId];
XHLiveManager *manager = [XHLiveManager sharedManager];
[manager joinRoom:kRoomId liveCarema:camera rootView:self.view playingFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height/2, 180, 240) success:^{
    NSLog(@"加入成功");
} failure:^(NSString *module, int errId, NSString *errMsg) {
    NSLog(@"加入失败");
}];    
```
    
**参数说明：**

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| camera | XHLiveCamera | 摄像头信息对象，将HTTP接口获取的主侧摄像头id传入进行初始化 |
| roomID | string | 房间 ID，就是获取房间列表时的 channel_no |
| rootView | UIView | 设置视频窗口建立在指定的UIView之上 |
| playingFrame | CGRect | 设置视频窗口在rootView上的frame信息 |
    
> **加入成功之后，视频会开始自动渲染在指定的窗口上**
    
##### 2. 切换摄像头

```
[XHLiveManager sharedManager] switchCamera:nil];
```

**参数说明：**

| 参数 | 类型 | 说明 |
| --- | --- | --- |
| cameraId | string | 指定切换的摄像头id，通常不需要指定，传nil会自动切换 |

##### 3. 上麦
    
```
[[XHLiveManager sharedManager] upToVideoMemberSuccess:^{
    NSLog(@"上麦成功");
} failure:^(NSString *module, int errId, NSString *errMsg) {
    NSLog(@"上麦失败");
}];
```
    
> **开始游戏后，需要先上麦保证视频低延时**

##### 4. 下麦

```
[[XHLiveManager sharedManager] downToVideoMemberSuccess:^{
    NSLog(@"下麦成功");
} failure:^(NSString *module, int errId, NSString *errMsg) {
    NSLog(@"下麦失败");
}];
```
    
> **游戏结束或异常，需要调用下麦，防止资源浪费和保证游戏正常逻辑**
    
_注意：一个游戏房间支持的上麦数量有限，因此业务上要保证只有游戏玩家处于上麦状态_
    
#### 退出直播间
* 用户退出游戏房间时，一定要调用此方法先退出，否则会影响下次用户加入其他游戏房间。

```
[[XHLiveManager sharedManager] quitRoomSuccess:^{
    NSLog(@"退出成功");
} failure:^(NSString *vgd, int errId, NSString *errMsg) {
    NSLog(@"退出失败");
}];
```


### 三、控制接入流程
#### websocket连接和操作
##### 1. 设置监听对象，这里是当前控制器，当然还需要遵该协议`<XHPlayerManagerDelegate>`

```
[manager setManagerListener:self];
```

##### 2. 建立websocket连接
    用户开始游戏获取到游戏websocket url之后，调用conncet方法，会先建立websocket连接，如果连接成功，则会自动投币，投币结果可参照投币回调方法。
    
    ```
    NSString *wsURL = @"ws://ws.open.wowgotcha.com:9090/play/5f21c3aa3badab94d35cdaa8b0f246e356fbe95f";
    XHPlayerManager *manager = [XHPlayerManager sharedManager];
    [manager setManagerListener:self];
    [manager connectWithWebSocketURL:wsURL success:^{
        NSLog(@"websocket连接成功");
    } failure:^(NSError *error) {
        NSLog(@"websocket连接失败");
    }];
    ```

##### 3. 发送操作指令
投币成功之后，可以发送以下操作指令，具体操作包括上下左右的按下与释放，还有最终下抓的操作，已封装在`XHPlayerOperation`枚举对象里

```
注意：
1、sdk已根据摄像头位置映射对应的操作指令，无须再次调整
2、方向键的操作都是成对存在的，需要实现按钮按下与释放的事件
```
    
发送指令方法：
    
```
// 按下‘上’按钮
[[XHPlayerManager sharedManager] sendOperation:XHPlayerOperationUpPress];
// 松开‘上’按钮
[[XHPlayerManager sharedManager] sendOperation:XHPlayerOperationUpRelease];
// 下抓
[[XHPlayerManager sharedManager] sendOperation:XHPlayerOperationCatch];
```

#### 事件/状态监听回调
* websocket连接成功，游戏进入roomReady状态

    ```
    - (void)roomReady:(NSDictionary *)readyInfo;
    ```

*  websocket连接成功，但用户在上局游戏未结束，会进入此回调，**`而不是roomReady回调`**，同时返回剩余时间等信息

    ```
    - (void)gameReconnect:(NSDictionary *)reconnectInfo;
    ```

* 投币结果，成功会接收到data，失败会接收errorMsg

    ```
    - (void)insertCoinResult:(BOOL)result data:(NSDictionary *)data errorMsg:(NSString *)errorMsg;
    ```

* 游戏抓取结果

    ```
    - (void)receiveGameResult:(BOOL)success sessionId:(NSString *)sessionId;
    ```

* 游戏结束后关闭websocket后进入该回调(可选)

    ```
    - (void)websocketClosed;
    ```
    

#### 其他
##### 1. 禁用音视频解码log方法
* 在调用`initSdk`之前调用以下方法即可,该方法可以屏蔽掉绝大部分大部分log

    ```
    [[XHLiveManager sharedManager] disableLogPrint];
    ```


