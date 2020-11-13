//
//  KPVideoPicker.m
//  react-native-kpframework-image-picker
//
//  Created by xukj on 2020/7/1.
//

#import "KPVideoPicker.h"
#import <Photos/Photos.h>
#import "KPCompression.h"

@interface KPVideoPicker()

@property (nonatomic, strong) KPCompression *compression;

@end

@implementation KPVideoPicker

- (void)getVideoAsset:(PHAsset *)forAsset
           coverImage:(UIImage *)coverImage
               option:(NSDictionary *)option
           completion:(KPPickerResultCompletion)completion
{
    PHImageManager *manager = [PHImageManager defaultManager];
    PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.networkAccessAllowed = YES;

    [manager requestAVAssetForVideo:forAsset
                            options:options
                      resultHandler:^(AVAsset * asset, AVAudioMix * audioMix, NSDictionary *info) {
        [self handleVideo:asset
                 fileName:[forAsset valueForKey:@"filename"]
          localIdentifier:forAsset.localIdentifier
               coverImage:coverImage
                   option:option
               completion:completion];
     }];
}

- (void)handleVideo:(AVAsset*)asset
           fileName:(NSString*)fileName
    localIdentifier:(NSString*)localIdentifier
         coverImage:(UIImage *)coverImage
             option:(NSDictionary *)option
         completion:(KPPickerResultCompletion)completion
{

    // 保存封面图片
    // ---
    NSString *coverPath = [self.compression persistFile:UIImageJPEGRepresentation(coverImage, 1) ext:@"jpeg"];

    // 视频文件压缩
    // ---
    NSURL *sourceURL = [(AVURLAsset *)asset URL];

    // create temp file
    NSString *tmpDirFullPath = [self.compression getTmpDirectory];
    NSString *filePath = [tmpDirFullPath stringByAppendingString:[[NSUUID UUID] UUIDString]];
    filePath = [filePath stringByAppendingString:@".mp4"];
    NSURL *outputURL = [NSURL fileURLWithPath:filePath];

    [self.compression compressVideo:sourceURL
                          outputURL:outputURL
                        withOptions:option
                            handler:^(AVAssetExportSession *exportSession) {
        
        if (exportSession.status == AVAssetExportSessionStatusCompleted) {
            AVAsset *compressedAsset = [AVAsset assetWithURL:outputURL];
            AVAssetTrack *track = [[compressedAsset tracksWithMediaType:AVMediaTypeVideo] firstObject];

            NSNumber *fileSizeValue = nil;
            [outputURL getResourceValue:&fileSizeValue
                                 forKey:NSURLFileSizeKey
                                  error:nil];

            
            KPPickerResult *result = [KPPickerResult videoPickerResultWithPath:[outputURL absoluteString]
                                                               localIdentifier:localIdentifier
                                                                      filename:fileName
                                                                         width:@(track.naturalSize.width)
                                                                        height:@(track.naturalSize.height)
                                                                          size:fileSizeValue
                                                                     sourceURL:[sourceURL absoluteString]
                                                                coverImagePath:coverPath];
            completion(result);
        } else {
            completion(nil);
        }
    }];
}

- (KPCompression *)compression
{
    if (_compression == nil) {
        _compression = [KPCompression sharedInstance];
    }
    return _compression;
}

@end
