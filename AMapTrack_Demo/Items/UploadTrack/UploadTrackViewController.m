//
//  UploadTrackViewController.m
//  AMapTrack_Demo
//
//  Created by liubo on 2018/7/26.
//  Copyright © 2018年 autonavi. All rights reserved.
//

#import "UploadTrackViewController.h"
#import <AMapTrackKit/AMapTrackKit.h>
#import <MAMapKit/MAMapKit.h>
#import "APIKey.h"
#import "ZHLocationHelper.h"
#import "Toast+UIView.h"

@interface UploadTrackViewController ()<AMapTrackManagerDelegate, MAMapViewDelegate>
{
    UIButton *_serviceBtn;
    UIButton *_gatherBtn;
    UISegmentedControl *_trackIDSegment;
    
    BOOL _serviceStarted;
    BOOL _gatherStarted;
    BOOL _createTrackID;
}

@property (nonatomic, strong) AMapTrackManager *trackManager;

@property (nonatomic, strong) MAMapView *mapView;

@end

@implementation UploadTrackViewController

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
    if ([kAMapTrackServiceID length] <= 0 || [kAMapTrackTerminalID length] <= 0) {
        _serviceBtn.enabled = NO;
        _gatherBtn.enabled = NO;

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
    option.serviceID = kAMapTrackServiceID;
    
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
/// @param button button
- (void)startTrackService:(UIButton *)button
{
    if (self.trackManager == nil) {
        return;
    }
    
    if (_serviceStarted == NO) {
        //开始服务
        AMapTrackManagerServiceOption *serviceOption = [[AMapTrackManagerServiceOption alloc] init];
        serviceOption.terminalID = kAMapTrackTerminalID;
        
        [self.trackManager startServiceWithOptions:serviceOption];
    } else {
        [self.trackManager stopService];
    }
}

/// 开始采集数据
/// @param button button
- (void)startTrackGather:(UIButton *)button
{
    if (self.trackManager == nil) {
        return;
    }
    
    if ([self.trackManager.terminalID length] <= 0) {
        NSLog(@"您需要先开始轨迹服务，才可以开始轨迹采集。");
        return;
    }
    
    if (_gatherStarted == NO) {
        if (_createTrackID == YES) {
            //需要创建trackID，创建成功后开始采集
            _trackIDSegment.enabled = NO;
            [self doCreateTrackName];
        } else {
            //不需要创建trackID，则直接开始采集
            _trackIDSegment.enabled = NO;
            [self.trackManager startGatherAndPack];
        }
    } else {
        [self.trackManager stopGaterAndPack];
    }
}

/// 创建设备Id
/// @param sender sender
- (void)createTerminalId:(id)sender {
    if (self.trackManager == nil) {
        return;
    }
    AMapTrackAddTerminalRequest *request = [[AMapTrackAddTerminalRequest alloc] init];
    request.serviceID = kAMapTrackServiceID;
    request.terminalName = @"yuanbenceshi003";
    request.terminalDesc = @"yuanbenceshi003-liqing";
    
    [self.trackManager AMapTrackAddTerminal:request];
}

- (void)trackIDSegmentAction:(UISegmentedControl *)segmentControl {
    if (segmentControl.selectedSegmentIndex == 1) {
        _createTrackID = YES;
    } else {
        _createTrackID = NO;
    }
}

#pragma mark - Helper

/// 创建trackID
/// 成功后执行回调函数 - (void)onAddTrackDone:(AMapTrackAddTrackRequest *)request response:(AMapTrackAddTrackResponse *)response
- (void)doCreateTrackName
{
    if (self.trackManager == nil) {
        return;
    }
    
    AMapTrackAddTrackRequest *request = [[AMapTrackAddTrackRequest alloc] init];
    request.serviceID = self.trackManager.serviceID;
    request.terminalID = self.trackManager.terminalID;
    
    [self.trackManager AMapTrackAddTrack:request];
}

#pragma mark - AMapTrackManagerDelegate

/// 当请求发生错误时，会调用代理的此方法。
/// @param error error
/// @param request request
- (void)didFailWithError:(NSError *)error associatedRequest:(id)request {
    if ([request isKindOfClass:[AMapTrackAddTrackRequest class]]) {
        _trackIDSegment.enabled = YES;
    }
    
    NSLog(@"didFailWithError:%@; --- associatedRequest:%@;", error, request);
    [self.view makeToast:[NSString stringWithFormat:@"didFailWithError:%@; --- associatedRequest:%@;", error, request] duration:1.0 position:@"bottom"];
}

#pragma mark - 开始Service回调/停止Service回调

- (void)onStartService:(AMapTrackErrorCode)errorCode
{
    if (errorCode == AMapTrackErrorOK) {
        //开始服务成功
        _serviceStarted = YES;
        _serviceBtn.backgroundColor = [UIColor greenColor];
    } else {
        //开始服务失败
        _serviceStarted = NO;
        _serviceBtn.backgroundColor = [UIColor whiteColor];
    }
    [self.view makeToast:[NSString stringWithFormat:@"开始Service回调:%ld", (long)errorCode] duration:1.0 position:@"bottom"];
    NSLog(@"开始Service回调:%ld", (long)errorCode);
}

- (void)onStopService:(AMapTrackErrorCode)errorCode
{
    _serviceStarted = NO;
    _gatherStarted = NO;
    _serviceBtn.backgroundColor = [UIColor whiteColor];
    _gatherBtn.backgroundColor = [UIColor whiteColor];
    _trackIDSegment.enabled = YES;
    
    NSLog(@"停止Service回调:%ld", (long)errorCode);
    [self.view makeToast:[NSString stringWithFormat:@"停止Service回调:%ld", (long)errorCode] duration:1.0 position:@"bottom"];
}

#pragma mark - 开始采集和上传回调

- (void)onStartGatherAndPack:(AMapTrackErrorCode)errorCode
{
    NSString *resultStr = @"开始采集成功";
    if (errorCode == AMapTrackErrorOK) {
        //开始采集成功
        _gatherStarted = YES;
        _gatherBtn.backgroundColor = [UIColor greenColor];
    } else {
        resultStr = @"开始采集失败";
        //开始采集失败
        _gatherStarted = NO;
        _gatherBtn.backgroundColor = [UIColor whiteColor];
    }
    [self.view makeToast:[NSString stringWithFormat:@"%@  和上传回调:%ld",resultStr, (long)errorCode] duration:1.0 position:@"bottom"];

    NSLog(@"开始采集和上传回调:%ld", (long)errorCode);
}

- (void)onStopGatherAndPack:(AMapTrackErrorCode)errorCode {
    _gatherStarted = NO;
    _gatherBtn.backgroundColor = [UIColor whiteColor];
    _trackIDSegment.enabled = YES;
    
//    [self.view makeToast:[NSString stringWithFormat:@"停止采集和上传回调:%ld", (long)errorCode] duration:1.0 position:@"bottom"];
    NSLog(@"停止采集和上传回调:%ld", (long)errorCode);
}

- (void)onStopGatherAndPack:(AMapTrackErrorCode)errorCode errorMessage:(NSString *)errorMessage {
    [self.view makeToast:[NSString stringWithFormat:@"停止采集和上传回调:%ld 失败信息：%@", (long)errorCode,errorMessage] duration:1.0 position:@"bottom"];
    NSLog(@"onStopGatherAndPack:%ld errorMessage:%@", (long)errorCode,errorMessage);
}

#pragma mark - 增加Track回调函数 -> 返回trackID

- (void)onAddTrackDone:(AMapTrackAddTrackRequest *)request response:(AMapTrackAddTrackResponse *)response
{
    NSLog(@"AddTrackDone%@", response.formattedDescription);
    NSString *resultStr = @"创建trackID成功";
    if (response.code == AMapTrackErrorOK) {
        //创建trackID成功，开始采集
        self.trackManager.trackID = response.trackID;
        [self.trackManager startGatherAndPack];
    } else {
        resultStr = @"创建trackID失败";
        //创建trackID失败
        _trackIDSegment.enabled = YES;
        NSLog(@"创建trackID失败");
    }
    
    [self.view makeToast:[NSString stringWithFormat:@"onAddTrackDone%@  state%@", response.formattedDescription,resultStr] duration:2.0 position:@"bottom"];
}

- (void)onAddTerminalDone:(AMapTrackAddTerminalRequest *)request response:(AMapTrackAddTerminalResponse *)response {
    if (response) {
        NSLog(@"serviceId:%@,terminalId:%@,terminalName:%@",response.serviceID,response.terminalID,response.terminalName);
    }
}


#pragma mark - MAMapViewDelegate

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation {
    
}


#pragma mark - 页面布局

- (void)initMapView
{
    if (self.mapView == nil)
    {
        self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 70)];
        [self.mapView setDelegate:self];
        [self.mapView setZoomLevel:16.0];
        [self.mapView setShowsUserLocation:YES];
        [self.mapView setUserTrackingMode:MAUserTrackingModeFollow];
        
        [self.view addSubview:self.mapView];
    }
}

- (void)initButtons
{
    _serviceBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _serviceBtn.frame = CGRectMake(10, CGRectGetMaxY(self.view.bounds) - 165, 100, 25);
    _serviceBtn.backgroundColor = [UIColor whiteColor];
    _serviceBtn.layer.borderWidth = 1;
    _serviceBtn.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [_serviceBtn setTitle:@"开始轨迹服务" forState:UIControlStateNormal];
    [_serviceBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_serviceBtn addTarget:self action:@selector(startTrackService:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_serviceBtn];
    
    _gatherBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _gatherBtn.frame = CGRectMake(120, CGRectGetMaxY(self.view.bounds) - 165, 100, 25);
    _gatherBtn.backgroundColor = [UIColor whiteColor];
    _gatherBtn.layer.borderWidth = 1;
    _gatherBtn.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [_gatherBtn setTitle:@"开始轨迹采集" forState:UIControlStateNormal];
    [_gatherBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_gatherBtn addTarget:self action:@selector(startTrackGather:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_gatherBtn];
    
    UIButton *createTidBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    createTidBtn.frame = CGRectMake(230, CGRectGetMaxY(self.view.bounds) - 165, 100, 25);
    createTidBtn.backgroundColor = [UIColor whiteColor];
    createTidBtn.layer.borderWidth = 1;
    createTidBtn.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [createTidBtn setTitle:@"创建termianlId" forState:UIControlStateNormal];
    [createTidBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [createTidBtn addTarget:self action:@selector(createTerminalId:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:createTidBtn];
    
    _trackIDSegment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"不自动创建", @"自动创建TrackID", nil]];
    _trackIDSegment.frame = CGRectMake(10, CGRectGetMaxY(self.view.bounds) - 135, 100, 25);
    [_trackIDSegment addTarget:self action:@selector(trackIDSegmentAction:) forControlEvents:UIControlEventValueChanged];
    _trackIDSegment.selectedSegmentIndex = 1;
    _trackIDSegment.backgroundColor = [UIColor whiteColor];
    [_trackIDSegment sizeToFit];
    [self.view addSubview:_trackIDSegment];
    //_trackIDSegment.selectedSegmentIndex = 1; -> _createTrackID = YES
    _createTrackID = YES;
}

@end
