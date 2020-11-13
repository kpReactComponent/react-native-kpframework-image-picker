//
//  KPNativeGallery.m
//  KPNativeGallery
//
//  Created by xukj on 2019/4/23.
//  Copyright © 2019 kpframework. All rights reserved.
//

#import "KPPicker.h"
#import <Photos/PHAsset.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <TZImagePickerController/TZImagePickerController.h>
#import "KPNativeImagePickerConstant.h"
#import "KPCompression.h"
#import "FLAnimatedImage.h"
#import "KPVideoPicker.h"
#import "KPPhotoPicker.h"

@interface KPPicker () <TZImagePickerControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) KPCompression *compression;
@property (nonatomic, strong) NSDictionary *options;
@property (nonatomic, strong) NSDictionary *defaultOptions;
@property (nonatomic, strong) RCTPromiseResolveBlock resolve;
@property (nonatomic, strong) RCTPromiseRejectBlock reject;

@property (nonatomic, strong) KPPhotoPicker *photoPicker;
@property (nonatomic, strong) KPVideoPicker *videoPicker;

@end

@implementation KPPicker

- (instancetype)init
{
    if (self = [super init]) {
        self.defaultOptions = @{
                                @"multiple": @NO,
                                @"cropping": @NO,
                                @"cropperCircleOverlay": @NO,
                                @"cropWidth": @400,
                                @"cropHeight": @400,
                                @"cropRadius": @200,
                                @"writeTempFile": @YES,
                                @"includeBase64": @NO,
                                @"includeExif": @NO,
                                @"compressVideo": @YES,
                                @"minFiles": @0,
                                @"maxFiles": @9,
                                @"compressImageMaxWidth": @600,
                                @"compressImageQuality": @0.8,
                                @"compressVideoPreset": @"MediumQuality",
                                @"loadingLabelText": @"正在处理",
                                @"mediaType": @"any",
                                @"showCamera": @YES,
                                };
        self.compression = [KPCompression sharedInstance];
    }

    return self;
}

- (void)dealloc
{
    NSLog(@"picker dealloc");
}

#pragma mark - public

- (void)openCamera:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    [self setConfiguration:options resolver:resolve rejecter:reject];
    [self requestTakePhotoAuth];
}

- (void)openPicker:(NSDictionary *)options resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    [self setConfiguration:options resolver:resolve rejecter:reject];
    [self showImagePickerController];
}

- (void)cleanSingle:(NSString *)path resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    BOOL deleted = [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];

    if (!deleted) {
        reject(ERROR_CLEANUP_ERROR_KEY, ERROR_CLEANUP_ERROR_MSG, nil);
    } else {
        resolve(nil);
    }
}

- (void)clean:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject
{
    if (![self.compression cleanTmpDirectory]) {
           reject(ERROR_CLEANUP_ERROR_KEY, ERROR_CLEANUP_ERROR_MSG, nil);
       } else {
           resolve(nil);
       }
}

#pragma mark - open picker

- (void)requestTakePhotoAuth
{
    RCTExecuteOnMainQueue(^{
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
            // 无相机权限 做一个友好的提示
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"无法使用相机" message:@"请在iPhone的""设置-隐私-相机""中允许访问相机" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }]];
            
            [RCTPresentedViewController() presentViewController:alertController animated:YES completion:nil];
        } else if (authStatus == AVAuthorizationStatusNotDetermined) {
            // fix issue 466, 防止用户首次拍照拒绝授权时相机页黑屏
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self requestTakePhotoAuth];
                    });
                }
            }];
            // 拍照之前还需要检查相册权限
        } else if ([PHPhotoLibrary authorizationStatus] == 2) { // 已被拒绝，没有相册权限，将无法保存拍的照片
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"无法访问相册" message:@"请在iPhone的""设置-隐私-相册""中允许访问相册" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
            [alertController addAction:[UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            }]];
            
            [RCTPresentedViewController() presentViewController:alertController animated:YES completion:nil];
        } else if ([PHPhotoLibrary authorizationStatus] == 0) { // 未请求过相册权限
            [[TZImageManager manager] requestAuthorizationWithCompletion:^{
                [self requestTakePhotoAuth];
            }];
        } else {
            [self showCameraPickerController];
        }
    });
}

- (void)showCameraPickerController
{
    // 提前定位
    UIImagePickerController *imagePickerVc = [[UIImagePickerController alloc] init];
    imagePickerVc.delegate = self;
    
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        imagePickerVc.sourceType = sourceType;
        NSMutableArray *mediaTypes = [NSMutableArray array];
        NSString *mediaType = [self.options objectForKey:@"mediaType"];
        if ([mediaType isEqualToString:@"video"]) {
            [mediaTypes addObject:(NSString *)kUTTypeMovie];
        }
        else if ([mediaType isEqualToString:@"photo"]) {
            [mediaTypes addObject:(NSString *)kUTTypeImage];
        }
        else {
            [mediaTypes addObject:(NSString *)kUTTypeImage];
            [mediaTypes addObject:(NSString *)kUTTypeMovie];
        }
        
        if (mediaTypes.count) {
            imagePickerVc.mediaTypes = mediaTypes;
        }
        
        [RCTPresentedViewController() presentViewController:imagePickerVc animated:YES completion:nil];
    } else {
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
    }
}

- (void)showImagePickerController
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized) {
            self.reject(ERROR_PICKER_UNAUTHORIZED_KEY, ERROR_PICKER_UNAUTHORIZED_MSG, nil);
            return;
        }
        
        RCTExecuteOnMainQueue(^{
            TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 columnNumber:4 delegate:self];
            imagePickerVc.sortAscendingByModificationDate = NO;
            imagePickerVc.allowPickingOriginalPhoto = YES;
            imagePickerVc.autoDismiss = NO;
            imagePickerVc.allowCameraLocation = NO;
            imagePickerVc.scaleAspectFillCrop = YES;

            // 配置类型视频、图片
            // ---
            NSString *mediaType = [self.options objectForKey:@"mediaType"];
            BOOL allowPickingVideo = YES;
            BOOL allowPickingImage = YES;
            BOOL allowPickingGIF = YES;
            BOOL allowTakeVideo = YES;
            BOOL allowTakePicture = YES;
            if ([mediaType isEqualToString:@"video"]) {
                allowPickingImage = NO;
                allowPickingGIF = NO;
                allowTakePicture = NO;
            }
            else if ([mediaType isEqualToString:@"photo"]) {
                allowPickingVideo = NO;
                allowTakeVideo = NO;
            }
            
            if (![[self.options objectForKey:@"showCamera"] boolValue]) {
                allowTakePicture = NO;
                allowTakeVideo = NO;
            }
            
            // 配置选择数量
            // ---
            int maxFiles = [[self.options objectForKey:@"maxFiles"] intValue];
            int minFiles = [[self.options objectForKey:@"minFiles"] intValue];
            BOOL multiple = [[self.options objectForKey:@"multiple"] boolValue];
            if (!multiple) {
                maxFiles = 1;
                minFiles = 0;
            }
                        
            // 配置裁剪;单选时生效,只能裁剪图片
            // ---
            BOOL needCircleCrop = [[self.options objectForKey:@"cropperCircleOverlay"] boolValue];
            BOOL allowCrop = [[self.options objectForKey:@"cropping"] boolValue];
            float cropWidth = [[self.options objectForKey:@"cropWidth"] floatValue];
            float cropHeight = [[self.options objectForKey:@"cropHeight"] floatValue];
            float cropRadius = [[self.options objectForKey:@"cropRadius"] floatValue];
            if (multiple) {
                needCircleCrop = NO;
                allowCrop = NO;
            }
            
            if (allowCrop) {
                allowPickingGIF = NO;
                allowPickingVideo = NO;
            }
            
            // 配置压缩;只支持指定宽度的图片压缩
            // ---
            float compressImageMaxWidth = [[self.options objectForKey:@"compressImageMaxWidth"] floatValue];
            
            imagePickerVc.maxImagesCount = maxFiles;
            imagePickerVc.minImagesCount = minFiles;
            
            imagePickerVc.allowCrop = allowCrop;
            imagePickerVc.needCircleCrop = needCircleCrop;
            if (needCircleCrop)
                imagePickerVc.circleCropRadius = KPPt(cropRadius);
            else
                imagePickerVc.cropRect = [self.compression cropRect:KPPt(cropWidth) height:KPPt(cropHeight)];
            
            imagePickerVc.allowTakePicture = allowTakePicture;
            imagePickerVc.allowTakeVideo = allowTakeVideo;
            imagePickerVc.allowPickingImage = allowPickingImage;
            imagePickerVc.allowPickingVideo = allowPickingVideo;
            imagePickerVc.allowPickingGif = allowPickingGIF;
            imagePickerVc.photoWidth = compressImageMaxWidth;
            imagePickerVc.photoPreviewMaxWidth = compressImageMaxWidth;
            
            [[TZImagePickerConfig sharedInstance] setGifImagePlayBlock:^(TZPhotoPreviewView *view, UIImageView *imageView, NSData *gifData, NSDictionary *info) {
                FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:gifData];
                FLAnimatedImageView *animatedImageView;
                for (UIView *subview in imageView.subviews) {
                    if ([subview isKindOfClass:[FLAnimatedImageView class]]) {
                        animatedImageView = (FLAnimatedImageView *)subview;
                        animatedImageView.frame = imageView.bounds;
                        animatedImageView.animatedImage = nil;
                    }
                }
                if (!animatedImageView) {
                    animatedImageView = [[FLAnimatedImageView alloc] initWithFrame:imageView.bounds];
                    animatedImageView.runLoopMode = NSDefaultRunLoopMode;
                    [imageView addSubview:animatedImageView];
                }
                animatedImageView.animatedImage = animatedImage;
            }];
            
            UIViewController *topController = RCTPresentedViewController();
            imagePickerVc.modalPresentationStyle = UIModalPresentationFullScreen;
            [topController presentViewController:imagePickerVc animated:YES completion:nil];
        });
    }];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)pickerController didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info
{
    [pickerController dismissViewControllerAnimated:YES completion:nil];
    
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    
    TZImagePickerController *tzImagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:nil];
    [tzImagePickerVc showProgressHUD];
    
    // 保存
    if ([type isEqualToString:@"public.image"]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        NSDictionary *meta = [info objectForKey:UIImagePickerControllerMediaMetadata];
        // save photo and get asset / 保存图片，获取到asset
        [[TZImageManager manager] savePhotoWithImage:image meta:meta location:nil completion:^(PHAsset *asset, NSError *error){
            [tzImagePickerVc hideProgressHUD];
            if (error) {
                NSLog(@"图片保存失败 %@",error);
            } else {
                TZAssetModel *assetModel = [[TZImageManager manager] createModelWithAsset:asset];
                
                if ([[self.options objectForKey:@"cropping"] boolValue]) {
                    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initCropTypeWithAsset:assetModel.asset photo:image completion:^(UIImage *cropImage, id asset) {
                        [self imagePickerController:RCTPresentedViewController() handlePhotos:@[cropImage] sourceAssets:@[asset] isSelectOriginalPhoto:NO infos:nil];
                    }];

                    imagePickerVc.imagePickerControllerDidCancelHandle = ^{
                        [self tz_imagePickerControllerDidCancel:nil];
                    };
                    
                    imagePickerVc.sortAscendingByModificationDate = NO;
                    imagePickerVc.allowPickingOriginalPhoto = YES;
                    imagePickerVc.autoDismiss = NO;
                    imagePickerVc.allowCameraLocation = NO;
                    imagePickerVc.scaleAspectFillCrop = YES;
                    
                    // 配置裁剪;单选时生效,只能裁剪图片
                    // ---
                    BOOL needCircleCrop = [[self.options objectForKey:@"cropperCircleOverlay"] boolValue];
                    float cropWidth = [[self.options objectForKey:@"cropWidth"] floatValue];
                    float cropHeight = [[self.options objectForKey:@"cropHeight"] floatValue];
                    float cropRadius = [[self.options objectForKey:@"cropRadius"] floatValue];
                    imagePickerVc.allowCrop = YES;
                    imagePickerVc.needCircleCrop = needCircleCrop;
                    if (needCircleCrop)
                        imagePickerVc.circleCropRadius = KPPt(cropRadius);
                    else
                        imagePickerVc.cropRect = [self.compression cropRect:KPPt(cropWidth) height:KPPt(cropHeight)];
                    [RCTPresentedViewController() presentViewController:imagePickerVc animated:YES completion:nil];
                }
                else {
                    // 配置压缩;只支持指定宽度的图片压缩
                    // ---
                    float compressImageMaxWidth = [[self.options objectForKey:@"compressImageMaxWidth"] floatValue];
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        UIImage *compressImage = [[TZImageManager manager] scaleImage:image toSize:CGSizeMake(compressImageMaxWidth, (int)(compressImageMaxWidth * image.size.height / image.size.width))];
                        [self imagePickerController:nil handlePhotos:@[compressImage] sourceAssets:@[asset] isSelectOriginalPhoto:NO infos:nil];
                    });
                }
            }
        }];
    }
    else if ([type isEqualToString:@"public.movie"]) {
        NSURL *videoUrl = [info objectForKey:UIImagePickerControllerMediaURL];
        if (videoUrl) {
            [[TZImageManager manager] saveVideoWithUrl:videoUrl location:nil completion:^(PHAsset *asset, NSError *error) {
                [tzImagePickerVc hideProgressHUD];
                if (!error) {
                    TZAssetModel *assetModel = [[TZImageManager manager] createModelWithAsset:asset];
                    [[TZImageManager manager] getPhotoWithAsset:assetModel.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
                        if (!isDegraded && photo) {
                            [self imagePickerController:RCTPresentedViewController() handlePhotos:@[photo] sourceAssets:@[asset] isSelectOriginalPhoto:NO infos:nil];
                        }
                    }];
                }
            }];
        }
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)pickerController
{
    [pickerController dismissViewControllerAnimated:YES completion:^{
        self.reject(ERROR_PICKER_CANCEL_KEY, ERROR_PICKER_CANCEL_MSG, nil);
    }];
}

#pragma mark - TZImagePickerControllerDelegate

- (void)imagePickerController:(TZImagePickerController *)picker
       didFinishPickingPhotos:(NSArray<UIImage *> *)photos
                 sourceAssets:(NSArray *)assets
        isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto
                        infos:(NSArray<NSDictionary *> *)infos
{
    [self imagePickerController:picker
                   handlePhotos:photos
                   sourceAssets:assets
          isSelectOriginalPhoto:isSelectOriginalPhoto
                          infos:infos];
}

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(PHAsset *)phAsset
{
    NSMutableArray *photos = [NSMutableArray new];
    [photos addObject:coverImage];
    NSMutableArray *assets = [NSMutableArray new];
    [assets addObject:phAsset];
    [self imagePickerController:picker handlePhotos:photos sourceAssets:assets isSelectOriginalPhoto:YES infos:nil];
}

- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingGifImage:(UIImage *)animatedImage sourceAssets:(PHAsset *)phAsset
{
    NSMutableArray *photos = [NSMutableArray new];
    [photos addObject:animatedImage];
    NSMutableArray *assets = [NSMutableArray new];
    [assets addObject:phAsset];
    [self imagePickerController:picker handlePhotos:photos sourceAssets:assets isSelectOriginalPhoto:YES infos:nil];
}

- (void)tz_imagePickerControllerDidCancel:(TZImagePickerController *)pickerController
{
    if (pickerController == nil) {
        self.reject(ERROR_PICKER_CANCEL_KEY, ERROR_PICKER_CANCEL_MSG, nil);
    }
    else {
        [pickerController dismissViewControllerAnimated:YES completion:^{
            self.reject(ERROR_PICKER_CANCEL_KEY, ERROR_PICKER_CANCEL_MSG, nil);
        }];
    }
}


#pragma mark - private

- (void) setConfiguration:(NSDictionary *)options
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject {

    self.resolve = resolve;
    self.reject = reject;
    self.options = [NSMutableDictionary dictionaryWithDictionary:self.defaultOptions];
    for (NSString *key in options.keyEnumerator) {
        [self.options setValue:options[key] forKey:key];
    }
}

- (void)imagePickerController:(UIViewController *)imagePickerController handlePhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto infos:(NSArray<NSDictionary *> *)infos
{
    PHImageManager *manager = [PHImageManager defaultManager];
    PHImageRequestOptions* options = [[PHImageRequestOptions alloc] init];
    options.synchronous = NO;
    options.networkAccessAllowed = YES;
    
    if (assets != nil) {
        // 多选，生成临时文件
        __weak __typeof(self) wself = self;
        NSMutableArray *selections = [[NSMutableArray alloc] init];
        [self showActivityIndicator:^(UIActivityIndicatorView *indicatorView, UIView *overlayView) {
            __strong __typeof(wself) self = wself;
            
            NSLock *lock = [[NSLock alloc] init];
            __block int processed = 0;

            for (int i = 0; i < assets.count; i++) {
                PHAsset *phAsset = assets[i];
                UIImage *photo = photos[i];

                if (phAsset.mediaType == PHAssetMediaTypeVideo) {
                    // 视频
                    [self.videoPicker getVideoAsset:phAsset
                                         coverImage:photo
                                             option:self.options
                                         completion:^(KPPickerResult* video) {
                        RCTExecuteOnMainQueue(^{
                            [lock lock];

                            if (video == nil) {
                                [indicatorView stopAnimating];
                                [overlayView removeFromSuperview];
                                if (imagePickerController) {
                                    [imagePickerController dismissViewControllerAnimated:YES completion:^{
                                        self.reject(ERROR_CANNOT_PROCESS_VIDEO_KEY, ERROR_CANNOT_PROCESS_VIDEO_MSG, nil);
                                    }];
                                }
                                else {
                                    self.reject(ERROR_CANNOT_PROCESS_VIDEO_KEY, ERROR_CANNOT_PROCESS_VIDEO_MSG, nil);
                                }
                                return;
                            }

                            [selections addObject:[video toJSON]];
                            processed++;
                            [lock unlock];

                            if (processed == [assets count]) {
                                [indicatorView stopAnimating];
                                [overlayView removeFromSuperview];
                                if (imagePickerController) {
                                    [imagePickerController dismissViewControllerAnimated:YES completion:^{
                                        self.resolve(selections);
                                    }];
                                }
                                else {
                                    self.resolve(selections);
                                }
                                return;
                            }
                        });
                    }];
                }
                else if (isSelectOriginalPhoto) {
                    // 使用原图
                    [manager
                     requestImageDataForAsset:phAsset
                     options:options
                     resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                                                
                        RCTExecuteOnMainQueue(^{
                            [lock lock];
                            @autoreleasepool {
                                KPPickerResult *result = [self.photoPicker getOriginalPhoto:phAsset
                                                                                  imageData:imageData
                                                                                    dataUTI:dataUTI
                                                                                orientation:orientation
                                                                                       info:info
                                                                                     option:self.options];
                                if (result == nil) {
                                    [indicatorView stopAnimating];
                                    [overlayView removeFromSuperview];
                                    if (imagePickerController) {
                                        [imagePickerController dismissViewControllerAnimated:YES completion:^{
                                            self.reject(ERROR_CANNOT_SAVE_IMAGE_KEY, ERROR_CANNOT_SAVE_IMAGE_MSG, nil);
                                        }];
                                    }
                                    else {
                                        self.reject(ERROR_CANNOT_SAVE_IMAGE_KEY, ERROR_CANNOT_SAVE_IMAGE_MSG, nil);
                                    }
                                    return;
                                }

                                [selections addObject:[result toJSON]];
                            }
                            processed++;
                            [lock unlock];
                            if (processed == [assets count]) {

                                 [indicatorView stopAnimating];
                                 [overlayView removeFromSuperview];
                                 if (imagePickerController) {
                                     [imagePickerController dismissViewControllerAnimated:YES completion:^{
                                         self.resolve(selections);
                                     }];
                                 }
                                 else {
                                     self.resolve(selections);
                                 }
                                 return;
                            }
                         });
                     }];
                }
                else {
                    // 压缩、裁剪后默认都是jpg 直接使用photo
                    RCTExecuteOnMainQueue(^{
                        [lock lock];
                        @autoreleasepool {
                            KPPickerResult *result = [self.photoPicker getCompressPhoto:phAsset image:photo option:self.options];
                            if (result == nil) {
                                [indicatorView stopAnimating];
                                [overlayView removeFromSuperview];
                                if (imagePickerController) {
                                    [imagePickerController dismissViewControllerAnimated:YES completion:^{
                                        self.reject(ERROR_CANNOT_SAVE_IMAGE_KEY, ERROR_CANNOT_SAVE_IMAGE_MSG, nil);
                                    }];
                                }
                                else {
                                    self.reject(ERROR_CANNOT_SAVE_IMAGE_KEY, ERROR_CANNOT_SAVE_IMAGE_MSG, nil);
                                }
                                return;
                            }
                            
                            [selections addObject:[result toJSON]];
                        }
                        processed++;
                        [lock unlock];

                        if (processed == [assets count]) {

                            [indicatorView stopAnimating];
                            [overlayView removeFromSuperview];
                            if (imagePickerController) {
                                [imagePickerController dismissViewControllerAnimated:YES completion:^{
                                    self.resolve(selections);
                                }];
                            }
                            else {
                                self.resolve(selections);
                            }
                            return;
                        }
                    });
                }
            }
        }];
    }
}

/**
 * 添加等待框
 */
- (void)showActivityIndicator:(void (^)(UIActivityIndicatorView*, UIView*))handler {
    
    RCTExecuteOnMainQueue(^{
        UIView *mainView = RCTPresentedViewController().view;

        // create overlay
        UIView *loadingView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        loadingView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.5];
        loadingView.clipsToBounds = YES;

        // create loading spinner
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.frame = CGRectMake(65, 40, activityView.bounds.size.width, activityView.bounds.size.height);
        activityView.center = loadingView.center;
        [loadingView addSubview:activityView];

        // create message
        UILabel *loadingLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 115, 130, 22)];
        loadingLabel.backgroundColor = [UIColor clearColor];
        loadingLabel.textColor = [UIColor whiteColor];
        loadingLabel.adjustsFontSizeToFitWidth = YES;
        CGPoint loadingLabelLocation = loadingView.center;
        loadingLabelLocation.y += [activityView bounds].size.height;
        loadingLabel.center = loadingLabelLocation;
        loadingLabel.textAlignment = NSTextAlignmentCenter;
        loadingLabel.text = [self.options objectForKey:@"loadingLabelText"];
        [loadingLabel setFont:[UIFont boldSystemFontOfSize:18]];
        [loadingView addSubview:loadingLabel];

        // show all
        [mainView addSubview:loadingView];
        [activityView startAnimating];

        handler(activityView, loadingView);
    });
}

#pragma mark - getter/setter

- (KPPhotoPicker *)photoPicker
{
    if (_photoPicker == nil) {
        _photoPicker = [[KPPhotoPicker alloc] init];
    }
    return _photoPicker;
}

- (KPVideoPicker *)videoPicker
{
    if (_videoPicker == nil) {
        _videoPicker = [[KPVideoPicker alloc] init];
    }
    return _videoPicker;
}

@end
