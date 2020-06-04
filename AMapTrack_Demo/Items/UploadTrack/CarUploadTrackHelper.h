//
//  CarUploadTrackHelper.h
//  AMapTrack_Demo
//
//  Created by 曾浩 on 2020/5/29.
//  Copyright © 2020 autonavi. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CarUploadTrackHelper : NSObject

+ (CarUploadTrackHelper *)shareHelper;

/// 开始轨迹服务
- (void)startTrackService:(NSString *)serviceId terminalId:(NSString *)terminalId trackId:(NSString *)trackId;

/// 停止轨迹服务
- (void)stopTrackService;

/// serviceId,terminalId,trackId 缺一不可
@property (nonatomic, copy) NSString *serviceId; // 服务id
@property (nonatomic, copy) NSString *terminalId; // 终端id
@property (nonatomic, copy) NSString *trackId; // 轨迹id

/// 服务是否开启状态
@property (nonatomic, assign) BOOL serviceStarted;

@end

NS_ASSUME_NONNULL_END
