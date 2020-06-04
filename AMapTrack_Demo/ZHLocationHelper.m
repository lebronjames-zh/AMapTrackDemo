//
//  ZHLocationHelper.m
//  YuanBenShengXianBusiness
//
//  Created by zenghao on 16/5/19.
//  Copyright © 2016年 zenghao. All rights reserved.
//
#define LocationTimeout 3  //   定位超时时间，可修改，最小2s
#define ReGeocodeTimeout 3 //   逆地理请求超时时间，可修改，最小2s

#import "ZHLocationHelper.h"
#import <AMapLocationKit/AMapLocationKit.h>
@interface ZHLocationHelper()<AMapLocationManagerDelegate>
{

}
@property(nonatomic,strong)AMapLocationManager *locationManager;

@property (nonatomic, copy) ZHLocationBlock locationBlock;
@property (nonatomic, copy) NSStringBlock addressBlock;
@property (nonatomic, copy) NSStringBlock cityBlock;
@property (nonatomic, copy) NSStringBlock areaBlock;

@property (nonatomic, copy) ZHLocationAddressBlock locationAddressBlock;
@property (nonatomic, copy) ZHLocationDetailAddressBlock locationDetailAddressBlock;

@end

@implementation ZHLocationHelper

+ (instancetype)shareHelper
{
    static ZHLocationHelper *locationHelper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        locationHelper = [[ZHLocationHelper alloc]init];
    });
    
    return locationHelper;
}

/**
 *  获取地理位置和坐标
 *
 *  @param locaiontBlock
 */
- (void)getLocationCoordinateAndAddress:(ZHLocationAddressBlock) locationAddressBlock
{
    self.locationAddressBlock = [locationAddressBlock copy];
    [self initLocationWithReGeocode:YES];
}

/**
 获取具体的定位信息。
 
 @param locaiontBlock locaiontBlock
 */
- (void)getLocationCoordinateAndDetailAddress:(ZHLocationDetailAddressBlock)locaiontBlock
{
    self.locationDetailAddressBlock = [locaiontBlock copy];
    [self initLocationWithReGeocode:YES];
}

//获取经纬度
- (void)getLocationCoordinate:(ZHLocationBlock)locaiontBlock
{
    self.locationBlock = [locaiontBlock copy];
    [self initLocationWithReGeocode:NO];
}

//获取地址
- (void)getAddress:(NSStringBlock)addressBlock
{
    self.addressBlock = [addressBlock copy];
    [self initLocationWithReGeocode:YES];
}

//获取市
- (void)getCity:(NSStringBlock)cityBlock
{
    self.cityBlock = [cityBlock copy];
    [self initLocationWithReGeocode:YES];
}

//获取省市区
- (void)getProviceCityArea:(NSStringBlock)AreaBlock
{
    self.areaBlock = [AreaBlock copy];
    [self initLocationWithReGeocode:YES];
}


- (AMapLocationManager *)locationManager
{
    if (!_locationManager)
    {
        _locationManager                 = [[AMapLocationManager alloc] init];
        _locationManager.delegate        = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        
        
        [_locationManager setLocationTimeout:LocationTimeout];
        [_locationManager setReGeocodeTimeout:ReGeocodeTimeout];
    }
    return _locationManager;
}

- (void)initLocationWithReGeocode:(BOOL)geoCode
{
    [self startLocationWithReGeocode:geoCode];
}

- (void)startLocationWithReGeocode:(BOOL)geoCode
{
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
//        [[UIApplication sharedApplication].keyWindow showAlertWithTitle:@"提示" message:@"源本云请求打开定位权限，方便为您提供周边天气和城市位置信息" confirmHandler:^(UIAlertAction *confirmAction) {
        NSLog(@"请求打开定位权限，方便为您提供周边天气和城市位置信息");
            NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
//        }];
        return;
    }
    
    [self.locationManager requestLocationWithReGeocode:geoCode completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        
        if (error)
        {
            NSLog(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
            
            if (error.code == AMapLocationErrorLocateFailed)
            {
                return;
            }
        }
        
        if (self.locationAddressBlock) {
            if (regeocode && location)
            {
                self.addressString = [NSString stringWithFormat:@"%@%@%@%@%@",regeocode.province,regeocode.city,regeocode.district,regeocode.street,regeocode.number];
                self.locationAddressBlock(location,self.addressString,regeocode.city);
                self.locationAddressBlock = nil;
                
                [self stopLocation];
            }
        }
        
        if (self.locationDetailAddressBlock) {
            if (regeocode && location)
            {
                self.locationDetailAddressBlock(location, regeocode.province, regeocode.city, regeocode.district, regeocode.street, regeocode.number);
                self.locationDetailAddressBlock = nil;
                [self stopLocation];
            }
        }
        
        if (self.locationBlock) {
            
            if (location)
            {
                NSLog(@"location:%@", location);
                self.lastCoordinate = location.coordinate;
                self.locationBlock(location);
                self.locationBlock = nil;
                [self stopLocation];
                
            }
        }
        
        NSLog(@"reGeocode:%@", regeocode);
        
        if (self.addressBlock) {
            if (regeocode)
            {
                self.addressString = [NSString stringWithFormat:@"%@%@%@%@%@",regeocode.province,regeocode.city,regeocode.district,regeocode.street,regeocode.number];
                self.addressBlock(self.addressString);
                self.addressBlock = nil;
                
                [self stopLocation];
            }

        }
        
        if (self.cityBlock) {
            if (regeocode)
            {
                self.addressString = [NSString stringWithFormat:@"%@",regeocode.city];
                self.cityBlock(self.addressString);
                self.cityBlock = nil;
                
                [self stopLocation];
            }
            
        }
        
        if (self.areaBlock) {
            if (regeocode)
            {
                self.addressString = [NSString stringWithFormat:@"%@,%@,%@",regeocode.province,regeocode.city,regeocode.district];
                self.areaBlock(self.addressString);
                self.areaBlock = nil;
                
                [self stopLocation];
            }
            
        }
        
    }];
    
}

/// 当plist配置NSLocationAlwaysUsageDescription或者NSLocationAlwaysAndWhenInUseUsageDescription，并且[CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined，会调用代理的此方法。此方法实现调用申请后台权限API即可：[locationManager requestAlwaysAuthorization](必须调用,不然无法正常获取定位权限)
/// @param manager manager
/// @param locationManager locationManager
- (void)amapLocationManager:(AMapLocationManager *)manager doRequireLocationAuth:(CLLocationManager *)locationManager
{
    [locationManager requestAlwaysAuthorization];
}

- (void)amapLocationManager:(AMapLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"%@",error);
}

- (void)stopLocation
{
    [self.locationManager stopUpdatingLocation];
    self.locationManager.delegate = nil;
    self.locationManager          = nil;
}

@end
