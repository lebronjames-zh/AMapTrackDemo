//
//  UploadTrackAuto2Controller.m
//  AMapTrack_Demo
//
//  Created by 曾浩 on 2020/5/29.
//  Copyright © 2020 autonavi. All rights reserved.
//

#import "UploadTrackAuto2Controller.h"
//#import <AMapTrackKit/AMapTrackKit.h>
#import <MAMapKit/MAMapKit.h>
#import "APIKey.h"
#import "Toast+UIView.h"
#import "CarUploadTrackHelper.h"

@interface UploadTrackAuto2Controller () <MAMapViewDelegate, UITextFieldDelegate>
{
    UIButton *_startServiceBtn;
    UIButton *_stopServiceBtn;
}

@property (nonatomic, strong) MAMapView *mapView;
@property (nonatomic, strong) UITextField *trackIdTField;

@end

@implementation UploadTrackAuto2Controller

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
    [self initTField];
    [self initButtons];
}

- (void)dealloc
{
    [self.mapView removeFromSuperview];
    self.mapView.delegate = nil;
    self.mapView = nil;
}


#pragma mark - Actions

/// 开始轨迹服务
- (void)startTrackService
{
    if (self.trackIdTField.text == nil) {
        [self.view makeToast:@"请输入trackId" duration:2.0 position:@"bottom"];
        return;
    }
//    [CarUploadTrackHelper shareHelper].trackId = self.trackIdTField.text;
    [[CarUploadTrackHelper shareHelper] startTrackService:@"xxx" terminalId:@"xxx" trackId:self.trackIdTField.text];
}

- (void)stopTrackService
{
    [[CarUploadTrackHelper shareHelper] stopTrackService];
}

#pragma mark - MAMapViewDelegate

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation {
    
}

#pragma mark - 页面布局

- (void)initMapView
{
    [self.view addSubview:self.mapView];
}

- (void)initTField
{
    [self.view addSubview:self.trackIdTField];
    
    self.trackIdTField.frame = CGRectMake(20, 20, 120, 35);
}

- (void)initButtons
{
    _startServiceBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _startServiceBtn.frame = CGRectMake(10, 70, 150, 25);
    _startServiceBtn.backgroundColor = [UIColor whiteColor];
    _startServiceBtn.layer.borderWidth = 1;
    _startServiceBtn.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [_startServiceBtn setTitle:@"开始轨迹服务并采集" forState:UIControlStateNormal];
    [_startServiceBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_startServiceBtn addTarget:self action:@selector(startTrackService) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_startServiceBtn];
    
    _stopServiceBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    _stopServiceBtn.frame = CGRectMake(10, 110, 100, 25);
    _stopServiceBtn.backgroundColor = [UIColor whiteColor];
    _stopServiceBtn.layer.borderWidth = 1;
    _stopServiceBtn.layer.borderColor = [UIColor darkGrayColor].CGColor;
    [_stopServiceBtn setTitle:@"停止" forState:UIControlStateNormal];
    [_stopServiceBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
    [_stopServiceBtn addTarget:self action:@selector(stopTrackService) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_stopServiceBtn];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - init

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
