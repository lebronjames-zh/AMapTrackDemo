//
//  MapTrackResponseModel.m
//  AMapTrack_Demo
//
//  Created by 曾浩 on 2020/5/27.
//  Copyright © 2020 autonavi. All rights reserved.
//

#import "MapTrackResponseModel.h"

@implementation MapTrackResponseModel

+ (NSDictionary *)modelContainerPropertyGenericClass {
    return @{@"points" : [MapTrackPointModel class]};
}

@end
