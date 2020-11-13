//
//  Compression.m
//  imageCropPicker
//
//  Created by Ivan Pusic on 12/24/16.
//  Copyright © 2016 Ivan Pusic. All rights reserved.
//

#import "KPCompression.h"

static KPCompression *compression = nil;
@implementation KPCompression

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        compression = [[KPCompression alloc] init];
    });
    return compression;
}

- (instancetype)init {
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] initWithDictionary:@{
                                                                                 @"640x480": AVAssetExportPreset640x480,
                                                                                 @"960x540": AVAssetExportPreset960x540,
                                                                                 @"1280x720": AVAssetExportPreset1280x720,
                                                                                 @"1920x1080": AVAssetExportPreset1920x1080,
                                                                                 @"LowQuality": AVAssetExportPresetLowQuality,
                                                                                 @"MediumQuality": AVAssetExportPresetMediumQuality,
                                                                                 @"HighestQuality": AVAssetExportPresetHighestQuality,
                                                                                 @"Passthrough": AVAssetExportPresetPassthrough,
                                                                                 }];
    
    if (@available(iOS 9.0, *)) {
        [dic addEntriesFromDictionary:@{@"3840x2160": AVAssetExportPreset3840x2160}];
    } else {
        // Fallback on earlier versions
    }
    
    self.exportPresets = dic;
    
    return self;
}

- (void)compressVideo:(NSURL*)inputURL
            outputURL:(NSURL*)outputURL
          withOptions:(NSDictionary*)options
              handler:(void (^)(AVAssetExportSession*))handler {
    
    NSString *presetKey = [options valueForKey:@"compressVideoPreset"];
    if (presetKey == nil) {
        presetKey = @"MediumQuality";
    }
    
    NSString *preset = [self.exportPresets valueForKey:presetKey];
    if (preset == nil) {
        preset = AVAssetExportPresetMediumQuality;
    }
    
    [[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:preset];
    exportSession.shouldOptimizeForNetworkUse = YES;
    exportSession.outputURL = outputURL;
    exportSession.outputFileType = AVFileTypeMPEG4;
    
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        handler(exportSession);
    }];
}

-(CGRect)cropRect:(float)width height:(float)height
{
    if (width <= 0 || height <= 0) return CGRectZero;
    
    CGRect screen = [UIScreen mainScreen].bounds;
    float rectWidth = width > CGRectGetWidth(screen) ? CGRectGetWidth(screen) : width;
    float rectHeight = height > CGRectGetHeight(screen) ? CGRectGetHeight(screen) : height;
    float x = (CGRectGetWidth(screen) - rectWidth) / 2;
    float y = (CGRectGetHeight(screen) - rectHeight) / 2;
    return CGRectMake(x, y, rectWidth, rectHeight);
}

// at the moment it is not possible to upload image by reading PHAsset
// we are saving image and saving it to the tmp location where we are allowed to access image later
- (NSString*)persistFile:(NSData*)data ext:(NSString *)ext
{
    // create temp file
    NSString *tmpDirFullPath = [self getTmpDirectory];
    NSString *filePath = [tmpDirFullPath stringByAppendingString:[[NSUUID UUID] UUIDString]];
    filePath = [NSString stringWithFormat:@"%@.%@", filePath, ext];

    // save cropped file
    BOOL status = [data writeToFile:filePath atomically:YES];
    if (!status) {
        return nil;
    }

    return filePath;
}

- (NSString *)determineMimeTypeFromImageData:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];

    switch (c) {
        case 0xFF:
            return @"image/jpeg";
        case 0x89:
            return @"image/png";
        case 0x47:
            return @"image/gif";
        case 0x49:
        case 0x4D:
            return @"image/tiff";
    }
    return @"";
}

- (NSString *)getTmpDirectory
{
    NSString *TMP_DIRECTORY = @"react-native-kpframework-image-picker/";
    NSString *tmpFullPath = [NSTemporaryDirectory() stringByAppendingString:TMP_DIRECTORY];

    BOOL isDir;
    BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:tmpFullPath isDirectory:&isDir];
    if (!exists) {
        [[NSFileManager defaultManager] createDirectoryAtPath: tmpFullPath
                                  withIntermediateDirectories:YES attributes:nil error:nil];
    }

    return tmpFullPath;
}

- (BOOL)cleanTmpDirectory {
    NSString* tmpDirectoryPath = [self getTmpDirectory];
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:tmpDirectoryPath error:NULL];

    for (NSString *file in tmpDirectory) {
        BOOL deleted = [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", tmpDirectoryPath, file] error:NULL];

        if (!deleted) {
            return NO;
        }
    }

    return YES;
}

@end
