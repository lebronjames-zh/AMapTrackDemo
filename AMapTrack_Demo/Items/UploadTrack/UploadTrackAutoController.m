//
//  UploadTrackAutoController.m
//  AMapTrack_Demo
//
//  Created by 曾浩 on 2020/5/28.
//  Copyright © 2020 autonavi. All rights reserved.
//
#define TrackServiceID @"xxx"
#define TrackTerminalID @"xxx"
#define TrackId @"xxx"

#import "UploadTrackAutoController.h"

#import <AMapTrackKit/AMapTrackKit.h>
#import <MAMapKit/MAMapKit.h>
#import "APIKey.h"
#import "ZHLocationHelper.h"
#import "Toast+UIView.h"

@interface UploadTrackAutoController ()<AMapTrackManagerDelegate, MAMapViewDelegate>
{
    UIButton *_startServiceBtn;
    UIButton *_stopServiceBtn;
    
    BOOL _serviceStarted;
//    BOOL _gatherStarted;
}

@property (nonatomic, strong) AMapTrackManager *trackManager;

@property (nonatomic, strong) MAMapView *mapView;

@end

@implementation UploadTrackAutoController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.toolbar.translucent = YES;
    self.navigationController.toolbarHidden = YES;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self initMapView];
    [self initButtons];
    [self initTrackManager];
}

- (void)dealloc
{
    [self.trackManager stopService];
    self.trackManager.delegate = nil;
    self.trackManager = nil;
    
    [self.mapView removeFromSuperview];
    self.mapView.delegate = nil;
    self.mapView = nil;
}

- (void)initTrackManager
{
    if ([TrackServiceID length] <= 0 || [TrackTerminalID length] <= 0) {
        _startServiceBtn.enabled = NO;
        _stopServiceBtn.enabled = NO;

        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"您需要指定ServiceID和TerminalID才可以使用轨迹服务"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    }
    
    //Service ID 需要根据需要进行修改
    AMapTrackManagerOptions *option = [[AMapTrackManagerOptions alloc] init];
    option.serviceID = TrackServiceID;
    
    //初始化AMapTrackManager
    self.trackManager = [[AMapTrackManager alloc] initWithOptions:option];
    self.trackManager.delegate = self;
    self.trackManager.distanceFilter = kCLDistanceFilterNone;
    
    //GPS精准度  默认值：kCLLocationAccuracyBest   最精准：kCLLocationAccuracyBestForNavigation
    
    self.trackManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    //配置定位属性
    [self.trackManager setLocalCacheMaxSize:50];
    [self.trackManager setAllowsBackgroundLocationUpdates:YES];
    [self.trackManager setPausesLocationUpdatesAutomatically:NO];
    [self.trackManager changeGatherAndPackTimeInterval:2 packTimeInterval:10];
}

#pragma mark - Actions

/// 开始轨迹服务
- (void)startTrackService
{
    if (self.trackManager == nil) {
        return;
    }
    
    if (_serviceStarted == YES) return;
    
    //开始服务
    AMapTrackManagerServiceOption *serviceOption = [[AMapTrackManagerServiceOption alloc] init];
    serviceOption.terminalID = TrackTerminalID;
    
    [self.trackManager startServiceWithOptions:serviceOption];
}

- (void)stopTrackService
{
    if (_serviceStarted == NO) return;
    
    [self.trackManager stopService];
    [self.trackManager stopGaterAndPack];
}

/// 开始采集数据
- (void)startTrackGather
{
    if (self.trackManager == nil) {
        return;
    }
    // ***** 上传到指定轨迹 *****
    self.trackManager.trackID = TrackId;
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
    [self.view makeToast:[NSString stringWithFormat:@"didFailWithError:%@; --- associatedRequest:%@;", error, request] duration:1.0 position:@"bottom"];
}

#pragma mark - 开始Service回调/停止Service回调

- (void)onStartService:(AMapTrackErrorCode)errorCode
{
    if (errorCode == AMapTrackErrorOK) {
        //开始服务成功
        _serviceStarted = YES;
        _startServiceBtn.backgroundColor = [UIColor lightTextColor];
        _startServiceBtn.userInteractionEnabled = NO;
        [self.view makeToast:[NSString stringWithFormat:@"开始服务成功回调:%ld", (long)errorCode] duration:1.0 position:@"bottom"];
        // 开始采集并上传数据
        [self startTrackGather];
    } else {
        //开始服务失败
        _serviceStarted = NO;
        _startServiceBtn.userInteractionEnabled = YES;
        _startServiceBtn.backgroundColor = [UIColor whiteColor];
        [self.view makeToast:[NSString stringWithFormat:@"开始服务失败回调:%ld", (long)errorCode] duration:1.0 position:@"bottom"];
    }
    
    NSLog(@"开始Service回调:%ld", (long)errorCode);
}

- (void)onStopService:(AMapTrackErrorCode)errorCode
{
    _startServiceBtn.userInteractionEnabled = YES;
    _serviceStarted = NO;
//    _gatherStarted = NO;
    _startServiceBtn.backgroundColor = [UIColor whiteColor];
    
    NSLog(@"停止Service回调:%ld", (long)errorCode);
    [self.view makeToast:[NSString stringWithFormat:@"停止Service回调:%ld", (long)errorCode] duration:1.0 position:@"bottom"];
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
    [self.view makeToast:[NSString stringWithFormat:@"%@  和上传回调:%ld",resultStr, (long)errorCode] duration:1.0 position:@"bottom"];

    NSLog(@"开始采集和上传回调:%ld", (long)errorCode);
}

- (void)onStopGatherAndPack:(AMapTrackErrorCode)errorCode {
//    _gatherStarted = NO;
    
//    [self.view makeToast:[NSString stringWithFormat:@"停止采集和上传回调:%ld", (long)errorCode] duration:1.0 position:@"bottom"];
    NSLog(@"停止采集和上传回调:%ld", (long)errorCode);
}

- (void)onStopGatherAndPack:(AMapTrackErrorCode)errorCode errorMessage:(NSString *)errorMessage {
    [self.view makeToast:[NSString stringWithFormat:@"停止采集和上传回调:%ld 失败信息：%@", (long)errorCode,errorMessage] duration:1.0 position:@"bottom"];
    NSLog(@"onStopGatherAndPack:%ld errorMessage:%@", (long)errorCode,errorMessage);
}

#pragma mark - MAMapViewDelegate

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation {
    
}


#pragma mark - 页面布局

- (void)initMapView
{
    [self.view addSubview:self.mapView];
}

- (void)initButtons
{
    _startServiceBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _startServiceBtn.frame = CGRectMake(10, 20, 150, 25);
    _startServiceBtn.backgroundColor = [UIColor whiteColor];
    _startServiceBtn.layer.borderWidth = 1;
    _startServiceBtn.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [_startServiceBtn setTitle:@"开始轨迹服务并采集" forState:UIControlStateNormal];
    [_startServiceBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_startServiceBtn addTarget:self action:@selector(startTrackService) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_startServiceBtn];
    
    _stopServiceBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _stopServiceBtn.frame = CGRectMake(10, 55, 100, 25);
    _stopServiceBtn.backgroundColor = [UIColor whiteColor];
    _stopServiceBtn.layer.borderWidth = 1;
    _stopServiceBtn.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [_stopServiceBtn setTitle:@"停止" forState:UIControlStateNormal];
    [_stopServiceBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_stopServiceBtn addTarget:self action:@selector(stopTrackService) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_stopServiceBtn];
}

#pragma mark - init

- (MAMapView *)mapView
{
    if (!_mapView) {
        _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 20)];
        _mapView.delegate = self;
        _mapView.zoomLevel = 16;
        _mapView.showsUserLocation = YES;
        _mapView.userTrackingMode = MAUserTrackingModeFollow;
    }
    return _mapView;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
