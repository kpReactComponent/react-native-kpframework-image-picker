//
//  KPNativeGallery.m
//  KPNativeGallery
//
//  Created by xukj on 2019/4/23.
//  Copyright © 2019 kpframework. All rights reserved.
//

#import "KPNativeImagePicker.h"
#import "KPPicker.h"

@interface KPNativeImagePicker ()

@property (nonatomic, strong) KPPicker *picker;

@end

@implementation KPNativeImagePicker

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

/**
 * 开启picker
 */
RCT_EXPORT_METHOD(openCamera:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.picker openCamera:options resolver:resolve rejecter:reject];
}

/**
 * 开启picker
 */
RCT_EXPORT_METHOD(openPicker:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    [self.picker openPicker:options resolver:resolve rejecter:reject];
}

/**
 * 清除缓存文件
 */
RCT_EXPORT_METHOD(cleanSingle:(NSString *) path
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {

    [self.picker cleanSingle:path resolver:resolve rejecter:reject];
}

/**
 * 清空缓存
 */
RCT_REMAP_METHOD(clean, resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    [self.picker clean:resolve rejecter:reject];
}

#pragma mark - getter/setter

- (KPPicker *)picker
{
    if (_picker == nil) {
        _picker = [[KPPicker alloc] init];
    }
    return _picker;
}

@end
