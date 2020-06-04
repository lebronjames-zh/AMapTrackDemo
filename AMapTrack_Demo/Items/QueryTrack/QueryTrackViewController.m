//
//  QueryTrackViewController.m
//  AMapTrack_Demo
//
//  Created by liubo on 2018/7/26.
//  Copyright © 2018年 autonavi. All rights reserved.
//

//字符串是否为空
#define kStringIsEmpty(str) ([str isKindOfClass:[NSNull class]] || str == nil || [str length] < 1 ? YES : NO )

#import "QueryTrackViewController.h"
#import <AMapTrackKit/AMapTrackKit.h>
#import <MAMapKit/MAMapKit.h>
#import "APIKey.h"
#import <YYModel.h>
#import "MapTrackResponseModel.h"

@interface QueryTrackViewController ()<AMapTrackManagerDelegate, MAMapViewDelegate, UITextFieldDelegate>
{
    UIButton *_queryTrackInfoBtn;
    UIButton *_queryTrackHstBtn;
    UISegmentedControl *_correctionSegment;
    UISegmentedControl *_recoupSegment;
    
    BOOL _correction;
    BOOL _recoup;
}

@property (nonatomic, strong) AMapTrackManager *trackManager;

@property (nonatomic, strong) MAMapView *mapView;

@property (nonatomic, strong) NSArray *tracksArray;

@property (nonatomic, strong) UITextField *terminalIdTField;
@property (nonatomic, strong) UITextField *trackIdTField;

@end

@implementation QueryTrackViewController

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
    [self initTField];
    [self initTrackManager];
}

- (void)dealloc {
    [self.trackManager stopService];
    self.trackManager.delegate = nil;
    self.trackManager = nil;
    
    [self.mapView removeFromSuperview];
    self.mapView.delegate = nil;
    self.mapView = nil;
}

- (void)initTField
{
    [self.view addSubview:self.terminalIdTField];
    [self.view addSubview:self.trackIdTField];
    
    self.terminalIdTField.frame = CGRectMake(20, 48, 120, 35);
    self.trackIdTField.frame = CGRectMake(20, 95, 120, 35);
}

- (void)initMapView
{
    if (self.mapView == nil)
    {
        self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 70)];
        [self.mapView setDelegate:self];
        [self.mapView setZoomLevel:13.0];
        [self.mapView setShowsUserLocation:YES];
        [self.mapView setUserTrackingMode:MAUserTrackingModeFollow];
        
        [self.view addSubview:self.mapView];
    }
}

- (void)initButtons
{
    _queryTrackInfoBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _queryTrackInfoBtn.frame = CGRectMake(10, CGRectGetMaxY(self.view.bounds) - 165, 100, 25);
    _queryTrackInfoBtn.backgroundColor = [UIColor whiteColor];
    _queryTrackInfoBtn.layer.borderWidth = 1;
    _queryTrackInfoBtn.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [_queryTrackInfoBtn setTitle:@"查询轨迹信息" forState:UIControlStateNormal];
    [_queryTrackInfoBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_queryTrackInfoBtn addTarget:self action:@selector(queryTrackInfoAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_queryTrackInfoBtn];
    
    _queryTrackHstBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _queryTrackHstBtn.frame = CGRectMake(120, CGRectGetMaxY(self.view.bounds) - 165, 100, 25);
    _queryTrackHstBtn.backgroundColor = [UIColor whiteColor];
    _queryTrackHstBtn.layer.borderWidth = 1;
    _queryTrackHstBtn.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [_queryTrackHstBtn setTitle:@"查询轨迹历史" forState:UIControlStateNormal];
    [_queryTrackHstBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_queryTrackHstBtn addTarget:self action:@selector(queryTrackHisAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_queryTrackHstBtn];
    
    UIButton *lastPointBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    lastPointBtn.frame = CGRectMake(230, CGRectGetMaxY(self.view.bounds) - 165, 100, 25);
    lastPointBtn.backgroundColor = [UIColor whiteColor];
    lastPointBtn.layer.borderWidth = 1;
    lastPointBtn.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [lastPointBtn setTitle:@"lastPoint" forState:UIControlStateNormal];
    [lastPointBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [lastPointBtn addTarget:self action:@selector(QueryLastPoint) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:lastPointBtn];
    
    _correctionSegment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"不纠偏", @"纠偏", nil]];
    _correctionSegment.frame = CGRectMake(10, CGRectGetMaxY(self.view.bounds) - 135, 100, 25);
    [_correctionSegment addTarget:self action:@selector(correctionSegmentAction:) forControlEvents:UIControlEventValueChanged];
    _correctionSegment.selectedSegmentIndex = 0;
    _correctionSegment.backgroundColor = [UIColor whiteColor];
    [_correctionSegment sizeToFit];
    [self.view addSubview:_correctionSegment];
    
    _recoupSegment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"不自动补点", @"自动补点", nil]];
    _recoupSegment.frame = CGRectMake(120, CGRectGetMaxY(self.view.bounds) - 135, 100, 25);
    [_recoupSegment addTarget:self action:@selector(recoupSegmentAction:) forControlEvents:UIControlEventValueChanged];
    _recoupSegment.selectedSegmentIndex = 0;
    _recoupSegment.backgroundColor = [UIColor whiteColor];
    [_recoupSegment sizeToFit];
    [self.view addSubview:_recoupSegment];
}

- (void)initTrackManager {
    if ([kAMapTrackServiceID length] <= 0 || [kAMapTrackTerminalID length] <= 0) {
        _queryTrackInfoBtn.enabled = NO;
        _queryTrackHstBtn.enabled = NO;
        
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
    
    //配置定位属性
    [self.trackManager setAllowsBackgroundLocationUpdates:YES];
    [self.trackManager setPausesLocationUpdatesAutomatically:NO];
}

#pragma mark - Actions

/// 搜索最近12小时以内上报的属于某个轨迹的轨迹点信息
/// @param button button
- (void)queryTrackInfoAction:(UIButton *)button {
    [self.view endEditing:YES];
    
    NSString *trackId = @"";
    NSString *terminalId = @"";
    if (!kStringIsEmpty(self.terminalIdTField.text)) {
        terminalId = self.terminalIdTField.text;
    } else if (!kStringIsEmpty(kAMapTrackTerminalID)) {
        terminalId = kAMapTrackTerminalID;
    }
    
    if (!kStringIsEmpty(self.trackIdTField.text)) {
        trackId = self.trackIdTField.text;
    }
    
    AMapTrackQueryTrackInfoRequest *request = [[AMapTrackQueryTrackInfoRequest alloc] init];
    request.serviceID = self.trackManager.serviceID;
    request.terminalID = kAMapTrackTerminalID;
    if (!kStringIsEmpty(trackId)) {
        request.trackID = trackId;
    }
    request.startTime = ([[NSDate date] timeIntervalSince1970] - 24*60*60) * 1000;
////    request.startTime = 1590560953155 + 1;
////    request.startTime = 1590560545900;
//    // startTime 要是在上个tracks endpoint endTime + 1;
    
    request.endTime = [[NSDate date] timeIntervalSince1970] * 1000;
    // pageSize 默认是20 查出来的tracks可能不全，设置为最大
    request.pageSize = 999;
    if (_correction) {
        request.correctionMode = @"denoise=1,mapmatch=1,threshold=0,mode=driving";
    }
    if (_recoup) {
        request.recoupMode = AMapTrackRecoupModeDriving;
    }
    
    [self.trackManager AMapTrackQueryTrackInfo:request];
}

/// 查询出某个终端在最近12小时内上传的所有轨迹点 + 距离
/// @param button button
- (void)queryTrackHisAction:(UIButton *)button {
    
    AMapTrackQueryTrackHistoryAndDistanceRequest *request = [[AMapTrackQueryTrackHistoryAndDistanceRequest alloc] init];
    request.serviceID = self.trackManager.serviceID;
    request.terminalID = kAMapTrackTerminalID;
    request.startTime = ([[NSDate date] timeIntervalSince1970] - 24*60*60) * 1000;
    request.endTime = [[NSDate date] timeIntervalSince1970] * 1000;

    if (_correction) {
        request.correctionMode = @"driving";
    }
    if (_recoup) {
        request.recoupMode = AMapTrackRecoupModeDriving;
    }
    
    [self.trackManager AMapTrackQueryTrackHistoryAndDistance:request];
}

- (void)correctionSegmentAction:(UISegmentedControl *)segmentControl {
    if (segmentControl.selectedSegmentIndex == 1) {
        _correction = YES;
    } else {
        _correction = NO;
    }
}

- (void)recoupSegmentAction:(UISegmentedControl *)segmentControl {
    if (segmentControl.selectedSegmentIndex == 1) {
        _recoup = YES;
    } else {
        _recoup = NO;
    }
}

#pragma mark - Helper

- (void)showPolylineWithTrackPoints:(NSArray<AMapTrackPoint *> *)points {
    int pointCount = (int)[points count];
    
    CLLocationCoordinate2D *allCoordinates = (CLLocationCoordinate2D *)malloc(pointCount * sizeof(CLLocationCoordinate2D));
    for (int i = 0; i < pointCount; i++) {
        allCoordinates[i].latitude = [[points objectAtIndex:i] coordinate].latitude;
        allCoordinates[i].longitude = [[points objectAtIndex:i] coordinate].longitude;
    }
    
    MAPolyline *polyline = [MAPolyline polylineWithCoordinates:allCoordinates count:pointCount];
    [self.mapView addOverlay:polyline];
    
    if (allCoordinates) {
        free(allCoordinates);
        allCoordinates = NULL;
    }
}

#pragma mark - AMapTrackManagerDelegate

- (void)didFailWithError:(NSError *)error associatedRequest:(id)request {
    NSLog(@"didFailWithError:%@; --- associatedRequest:%@;", error, request);
}

#pragma mark - 查询某个终端最后一次上报的位置信息

- (void)QueryLastPoint
{
    AMapTrackQueryLastPointRequest *request = [[AMapTrackQueryLastPointRequest alloc] init];
    request.serviceID = kAMapTrackServiceID;
    request.terminalID = kAMapTrackTerminalID;
//    request.trackID = TrackID;
    [self.trackManager AMapTrackQueryLastPoint:request];
}

- (void)onQueryLastPointDone:(AMapTrackQueryLastPointRequest *)request response:(AMapTrackQueryLastPointResponse *)response
{
    //查询成功
    NSLog(@"onQueryLastPointDone%@", response.formattedDescription);
}

#pragma mark - 查询轨迹历史数据和行驶距离回调函数

- (void)onQueryTrackHistoryAndDistanceDone:(AMapTrackQueryTrackHistoryAndDistanceRequest *)request response:(AMapTrackQueryTrackHistoryAndDistanceResponse *)response {
    NSLog(@"onQueryTrackHistoryAndDistanceDone%@", response.formattedDescription);
    
    if ([[response points] count] > 0) {
        [self.mapView removeOverlays:[self.mapView overlays]];
        [self showPolylineWithTrackPoints:[response points]];
        [self.mapView showOverlays:self.mapView.overlays animated:NO];
    }
}

#pragma mark - 查询轨迹历史数据回调函数 + trackID

- (void)onQueryTrackInfoDone:(AMapTrackQueryTrackInfoRequest *)request response:(AMapTrackQueryTrackInfoResponse *)response {
    NSLog(@"onQueryTrackInfoDone%@", response.formattedDescription);
    
//    self.tracksArray = [NSArray yy_modelArrayWithClass:[MapTrackResponseModel class] json:response.tracks];
    
    [self.mapView removeOverlays:[self.mapView overlays]];
    for (AMapTrackBasicTrack *track in response.tracks) {
        if ([[track points] count] > 0) {
            [self showPolylineWithTrackPoints:[track points]];
        }
    }
    [self.mapView showOverlays:self.mapView.overlays animated:NO];
}

#pragma mark - MapView Delegate

- (MAOverlayRenderer *)mapView:(MAMapView *)mapView rendererForOverlay:(id<MAOverlay>)overlay {
    if ([overlay isKindOfClass:[MAPolyline class]]) {
        
        MAPolylineRenderer * polylineRenderer = [[MAPolylineRenderer alloc] initWithOverlay:overlay];
        polylineRenderer.lineWidth = 12.f;
        
        return polylineRenderer;
    }
    
    return nil;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - init

- (UITextField *)terminalIdTField
{
    if (!_terminalIdTField) {
        _terminalIdTField = [[UITextField alloc] init];
        _terminalIdTField.backgroundColor = UIColor.whiteColor;
        _terminalIdTField.delegate = self;
        _terminalIdTField.font = [UIFont systemFontOfSize:14];
        _terminalIdTField.placeholder = @"输入设备Id";
        _terminalIdTField.layer.cornerRadius = 5;
        _terminalIdTField.layer.masksToBounds = YES;
        _terminalIdTField.textAlignment = NSTextAlignmentCenter;
        _terminalIdTField.returnKeyType = UIReturnKeyDone;
        _terminalIdTField.clearButtonMode = UITextFieldViewModeWhileEditing;
        _terminalIdTField.text = @"256914327";
    }
    return _terminalIdTField;
}

- (UITextField *)trackIdTField
{
    if (!_trackIdTField) {
        _trackIdTField = [[UITextField alloc] init];
        _trackIdTField.backgroundColor = UIColor.whiteColor;
        _trackIdTField.delegate = self;
        _trackIdTField.font = [UIFont systemFontOfSize:14];
        _trackIdTField.placeholder = @"输入trackId";
        _trackIdTField.layer.cornerRadius = 5;
        _trackIdTField.layer.masksToBounds = YES;
        _trackIdTField.textAlignment = NSTextAlignmentCenter;
        _trackIdTField.returnKeyType = UIReturnKeyDone;
        _trackIdTField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }
    return _trackIdTField;
}

@end
