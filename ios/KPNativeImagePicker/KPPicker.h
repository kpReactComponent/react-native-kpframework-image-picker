//
//  KPImagePicker.h
//  react-native-kpframework-image-picker
//
//  Created by xukj on 2020/7/1.
//

#import <Foundation/Foundation.h>
#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#import <React/RCTUtils.h>
#else
#import "RCTBridgeModule.h"
#import "RCTUtils.h"
#endif

@interface KPPicker : NSObject

- (void)openCamera:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;

- (void)openPicker:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;

- (void)cleanSingle:(NSString *)path resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;

- (void)clean:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject;

@end
