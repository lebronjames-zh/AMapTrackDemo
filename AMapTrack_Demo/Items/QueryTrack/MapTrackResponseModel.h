//
//  MapTrackResponseModel.h
//  AMapTrack_Demo
//
//  Created by 曾浩 on 2020/5/27.
//  Copyright © 2020 autonavi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AMapTrackKit/AMapTrackKit.h>
#import "MapTrackPointModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface MapTrackResponseModel : NSObject

///行驶距离，单位米
@property (nonatomic, assign) NSUInteger distance;

///符合要求点的个数
@property (nonatomic, assign) NSUInteger count;

///起点信息，仅在page=1的时候显示相关信息
@property (nonatomic, strong) AMapTrackPoint *startPoint;

///终点信息，仅在page=1的时候显示相关信息
@property (nonatomic, strong) AMapTrackPoint *endPoint;

///历史轨迹数据
@property (nonatomic, strong) NSArray<MapTrackPointModel *> *points;

@end

NS_ASSUME_NONNULL_END
