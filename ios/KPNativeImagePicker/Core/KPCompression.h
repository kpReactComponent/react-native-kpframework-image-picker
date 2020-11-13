//
//  Compression.h
//  imageCropPicker
//
//  Created by Ivan Pusic on 12/24/16.
//  Copyright © 2016 Ivan Pusic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface KPCompression : NSObject

@property NSDictionary *exportPresets;

+ (instancetype)sharedInstance;

- (void)compressVideo:(NSURL*)inputURL
            outputURL:(NSURL*)outputURL
          withOptions:(NSDictionary*)options
              handler:(void (^)(AVAssetExportSession*))handler;

- (CGRect)cropRect:(float)width height:(float)height;

- (NSString *)determineMimeTypeFromImageData:(NSData *)data;

// at the moment it is not possible to upload image by reading PHAsset
// we are saving image and saving it to the tmp location where we are allowed to access image later
- (NSString*)persistFile:(NSData*)data ext:(NSString *)ext;
- (NSString *)getTmpDirectory;
- (BOOL)cleanTmpDirectory;

@end
