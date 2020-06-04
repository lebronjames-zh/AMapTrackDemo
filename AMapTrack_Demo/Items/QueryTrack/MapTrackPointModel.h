//
//  MapTrackPointModel.h
//  AMapTrack_Demo
//
//  Created by 曾浩 on 2020/5/27.
//  Copyright © 2020 autonavi. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MapTrackPointModel : NSObject

///Point的坐标信息
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;

///Point的定位时间，单位毫秒
@property (nonatomic, assign) long long locateTime;

///Point的速度信息，单位km/h
@property (nonatomic, assign) double speed;

///Point的航向信息
@property (nonatomic, assign) double direction;

///Point的高度信息
@property (nonatomic, assign) double height;

///Point的定位精确度
@property (nonatomic, assign) double accuracy;

///Point的上传时间，仅在从服务端检索返回时有效
@property (nonatomic, assign) long long createTime;

@end

NS_ASSUME_NONNULL_END
