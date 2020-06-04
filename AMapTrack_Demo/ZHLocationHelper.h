//
//  ZHLocationHelper.h
//  YuanBenShengXianBusiness
//
//  Created by zenghao on 16/5/19.
//  Copyright © 2016年 zenghao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

//typedef void (^LocationBlock)(CLLocation *location);
typedef void (^ZHLocationBlock)(CLLocation *location);
typedef void (^ZHLocationAddressBlock)(CLLocation *location,NSString *address,NSString *city);
typedef void (^ZHLocationDetailAddressBlock)(CLLocation *location,NSString *province,NSString *city,NSString *district,NSString *street,NSString *number);
typedef void (^NSStringBlock)(NSString *addressString);

@interface ZHLocationHelper : NSObject

@property(nonatomic) CLLocationCoordinate2D lastCoordinate;
@property(nonatomic,copy) NSString *addressString;

+ (instancetype)shareHelper;



/**
 *  获取地理位置和坐标
 *
 *  @param locaiontBlock
 */
- (void)getLocationCoordinateAndAddress:(ZHLocationAddressBlock) locaiontBlock;

/**
 获取具体的定位信息。

 @param locaiontBlock locaiontBlock 
 */
- (void)getLocationCoordinateAndDetailAddress:(ZHLocationDetailAddressBlock)locaiontBlock;

/**
 *  获取坐标
 *
 *  @param locaiontBlock locaiontBlock description
 */
- (void)getLocationCoordinate:(ZHLocationBlock) locaiontBlock;
/**
 *  获取详细地址
 *
 *  @param addressBlock addressBlock description
 */
- (void)getAddress:(NSStringBlock)addressBlock;
/**
 *  获取城市
 *
 *  @param cityBlock cityBlock description
 */
- (void)getCity:(NSStringBlock)cityBlock;
/**
 *  获取省市区
 *
 *  @param AreaBlock AreaBlock description
 */
- (void)getProviceCityArea:(NSStringBlock)AreaBlock;
@end
