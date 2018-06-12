//
//  GameSocketManager.m
//  wowgotcha
//
//  Created by Michael on 2017/12/2.
//  Copyright © 2017年 renrele. All rights reserved.
//

#import "GameSocketManager.h"
#import "XHMacro.h"

@interface GameSocketManager ()

@property (nonatomic, assign) NSUInteger msgIndex;

@end

@implementation GameSocketManager

- (void)openWithURL:(NSString *)url connect:(FLSocketDidConnectBlock)connect receive:(void (^)(NSDictionary *response))receive failure:(FLSocketDidFailBlock)failure{
    self.msgIndex = 0;
    [self fl_open:url connect:connect receive:^(id message, FLSocketReceiveType type) {
        NSDictionary *respose = [self dictionaryWithJsonString:message];
//        GameSocketResponseModel *respon = [GameSocketResponseModel mj_objectWithKeyValues:result];
        if (receive) {
            receive(respose);
        }
        
    } failure:failure];
}

- (NSString *)sendMessage:(NSDictionary *)data method:(NSString *)method{
    self.msgIndex ++;
    NSMutableDictionary *postDic = [[NSMutableDictionary alloc] init];
    [postDic setObject:[NSString stringWithFormat:@"%ld",self.msgIndex] forKey:@"id"];
    [postDic setObject:method forKey:@"method"];
    if (data && data.count) {
        [postDic setObject:data forKey:@"params"];
    }
    
    NSString *postData = [self dictionaryToJson:postDic];
//    XHDebugLog(@"******web socket发送的报文%@",postData);
    [self fl_send:postData];
        
    return [NSString stringWithFormat:@"%ld",self.msgIndex];
}

- (void)closeConnect{
    __weak __typeof(self) wself = self;
    [self fl_close:^(NSInteger code, NSString *reason, BOOL wasClean) {
//        MWLog(@"websocket关闭%@",reason);
        wself.msgIndex = 0;
    }];
}

#pragma mark ------ 格式转化
// json格式字符串转字典：
- (NSDictionary *)dictionaryWithJsonString:(NSString *)jsonString{
    if (jsonString == nil) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData
                                                        options:NSJSONReadingMutableContainers
                                                          error:&err];
    if(err) {
//        XHDebugLog(@"json解析失败：%@",err);
        return nil;
    }
    return dic;
}
//字典转json格式字符串：
- (NSString*)dictionaryToJson:(NSDictionary *)dic{
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
