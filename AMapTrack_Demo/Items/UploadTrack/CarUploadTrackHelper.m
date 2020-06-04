//
//  CarUploadTrackHelper.m
//  AMapTrack_Demo
//
//  Created by 曾浩 on 2020/5/29.
//  Copyright © 2020 autonavi. All rights reserved.
//

//#define TrackServiceID @"xxx"
//#define TrackTerminalID @"xxx"

#import "CarUploadTrackHelper.h"
#import <AMapTrackKit/AMapTrackKit.h>
#import <MAMapKit/MAMapKit.h>
#import "APIKey.h"
#import "ZHLocationHelper.h"
#import "Toast+UIView.h"

@interface CarUploadTrackHelper () <AMapTrackManagerDelegate>

@property (nonatomic, strong) AMapTrackManager *trackManager;

@end

@implementation CarUploadTrackHelper

+ (CarUploadTrackHelper *)shareHelper
{
    static CarUploadTrackHelper *trackHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        trackHelper = [[self alloc] init];
    });
    return trackHelper;
}

- (AMapTrackManager *)trackManager
{
    if (!_trackManager) {
        //Service ID 需要根据需要进行修改
        AMapTrackManagerOptions *option = [[AMapTrackManagerOptions alloc] init];
        option.serviceID = self.serviceId;
        
        //初始化AMapTrackManager
        _trackManager = [[AMapTrackManager alloc] initWithOptions:option];
        _trackManager.delegate = self;
        _trackManager.distanceFilter = kCLDistanceFilterNone;
        
        //GPS精准度  默认值：kCLLocationAccuracyBest   最精准：kCLLocationAccuracyBestForNavigation
        
        _trackManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        //配置定位属性
        [_trackManager setLocalCacheMaxSize:50];
        [_trackManager setAllowsBackgroundLocationUpdates:YES];
        [_trackManager setPausesLocationUpdatesAutomatically:NO];
        [_trackManager changeGatherAndPackTimeInterval:2 packTimeInterval:10];
    }
    return _trackManager;
}

#pragma mark - Actions

- (void)startTrackService:(NSString *)serviceId terminalId:(NSString *)terminalId trackId:(NSString *)trackId
{
    self.serviceId = serviceId;
    self.terminalId = terminalId;
    self.trackId = trackId;
    if (self.trackManager == nil) {
        return;
    }
    
    if (self.serviceStarted == YES) return;
#warning 这里需要修改
    if (self.trackId == nil) {
        return;
    }
    
    //开始服务
    AMapTrackManagerServiceOption *serviceOption = [[AMapTrackManagerServiceOption alloc] init];
    serviceOption.terminalID = terminalId;
    
    [self.trackManager startServiceWithOptions:serviceOption];
}

/// 停止轨迹服务
- (void)stopTrackService
{
    if (self.serviceStarted == NO) return;
    
    [self.trackManager stopService];
    [self.trackManager stopGaterAndPack];
    
    self.trackManager.delegate = nil;
    self.trackManager = nil;
}

/// 开始采集数据
- (void)startTrackGather
{
    if (self.trackManager == nil) {
        return;
    }
    // ***** 上传到指定轨迹 *****
    self.trackManager.trackID = self.trackId;
    [self.trackManager startGatherAndPack];
}

/// 停止采集数据
- (void)stopTrackGather
{
    [self.trackManager stopGaterAndPack];
}

#pragma mark - AMapTrackManagerDelegate

/// 当请求发生错误时，会调用代理的此方法。
/// @param error error
/// @param request request
- (void)didFailWithError:(NSError *)error associatedRequest:(id)request {
    NSLog(@"didFailWithError:%@; --- associatedRequest:%@;", error, request);
//    [self.view makeToast:[NSString stringWithFormat:@"didFailWithError:%@; --- associatedRequest:%@;", error, request] duration:1.0 position:@"bottom"];
}

#pragma mark - 开始Service回调/停止Service回调

- (void)onStartService:(AMapTrackErrorCode)errorCode
{
    if (errorCode == AMapTrackErrorOK) {
        //开始服务成功
        self.serviceStarted = YES;
//        [self.view makeToast:[NSString stringWithFormat:@"开始服务成功回调:%ld", (long)errorCode] duration:1.0 position:@"bottom"];
        // 开始采集并上传数据
        [self startTrackGather];
    } else {
        //开始服务失败
        self.serviceStarted = NO;
//        [self.view makeToast:[NSString stringWithFormat:@"开始服务失败回调:%ld", (long)errorCode] duration:1.0 position:@"bottom"];
    }
    
    NSLog(@"开始Service回调:%ld", (long)errorCode);
}

- (void)onStopService:(AMapTrackErrorCode)errorCode
{
    self.serviceStarted = NO;
    
    NSLog(@"停止Service回调:%ld", (long)errorCode);
//    [self.view makeToast:[NSString stringWithFormat:@"停止Service回调:%ld", (long)errorCode] duration:1.0 position:@"bottom"];
}

#pragma mark - 开始采集和上传回调

- (void)onStartGatherAndPack:(AMapTrackErrorCode)errorCode
{
    NSString *resultStr = @"开始采集成功";
    if (errorCode == AMapTrackErrorOK) {
        //开始采集成功
//        _gatherStarted = YES;
    } else {
        resultStr = @"开始采集失败";
        //开始采集失败
//        _gatherStarted = NO;
    }
//    [self.view makeToast:[NSString stringWithFormat:@"%@  和上传回调:%ld",resultStr, (long)errorCode] duration:1.0 position:@"bottom"];

    NSLog(@"开始采集和上传回调:%ld", (long)errorCode);
}

- (void)onStopGatherAndPack:(AMapTrackErrorCode)errorCode {
//    _gatherStarted = NO;
    
//    [self.view makeToast:[NSString stringWithFormat:@"停止采集和上传回调:%ld", (long)errorCode] duration:1.0 position:@"bottom"];
    NSLog(@"停止采集和上传回调:%ld", (long)errorCode);
}

- (void)onStopGatherAndPack:(AMapTrackErrorCode)errorCode errorMessage:(NSString *)errorMessage {
//    [self.view makeToast:[NSString stringWithFormat:@"停止采集和上传回调:%ld 失败信息：%@", (long)errorCode,errorMessage] duration:1.0 position:@"bottom"];
    NSLog(@"onStopGatherAndPack:%ld errorMessage:%@", (long)errorCode,errorMessage);
}


@end
