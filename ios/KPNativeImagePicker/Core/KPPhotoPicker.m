//
//  KPPhotoPicker.m
//  react-native-kpframework-image-picker
//
//  Created by xukj on 2020/7/1.
//

#import "KPPhotoPicker.h"
#import "KPCompression.h"

@interface KPPhotoPicker()

@property (nonatomic, strong) KPCompression *compression;

@end

@implementation KPPhotoPicker

- (KPPickerResult *)getOriginalPhoto:(PHAsset *)phAsset
                           imageData:(NSData *)imageData
                             dataUTI:(NSString *)dataUTI
                         orientation:(UIImageOrientation)orientation
                                info:(NSDictionary *)info
                              option:(NSDictionary *)option
{
    NSURL *sourceURL = [info objectForKey:@"PHImageFileURLKey"];
    UIImage *imgT = [UIImage imageWithData:imageData];
    NSString *mimeType = [self.compression determineMimeTypeFromImageData:imageData];
    KPPickerResult *imageResult = [KPPickerResult photoPickerResultWithData:imageData mimeType:mimeType image:imgT];
    
    NSString *filePath = @"";
    if([[option objectForKey:@"writeTempFile"] boolValue]) {
        // 文件后缀
        NSString *ext = [mimeType stringByReplacingOccurrencesOfString:@"image/" withString:@""];
        filePath = [self.compression persistFile:imageResult.imageData ext:ext];

        if (filePath == nil) {
            return nil;
        }
    }

    NSDictionary* exif = nil;
    if([[option objectForKey:@"includeExif"] boolValue]) {
        exif = [[CIImage imageWithData:imageData] properties];
    }
    
    imageResult.path = filePath;
    imageResult.exif = exif;
    imageResult.sourceURL = [sourceURL absoluteString];  // iOS13开始无法取得sourceURL
    imageResult.localIdentifier = phAsset.localIdentifier;
    imageResult.filename = [phAsset valueForKey:@"filename"];
    imageResult.data = [[option objectForKey:@"includeBase64"] boolValue] ? [imageResult.imageData base64EncodedStringWithOptions:0]: nil;
    imageResult.creationDate = phAsset.creationDate;
    imageResult.modificationDate = phAsset.modificationDate;
    return imageResult;
}

- (KPPickerResult *)getCompressPhoto:(PHAsset *)phAsset image:(UIImage *)photo option:(NSDictionary *)option
{
    UIImage *imgT = photo;
    float compressImageQuality = [[option objectForKey:@"compressImageQuality"] floatValue];
    NSData *imageData = UIImageJPEGRepresentation(photo, compressImageQuality);
    NSString *mimeType = [self.compression determineMimeTypeFromImageData:imageData];
    KPPickerResult *imageResult = [KPPickerResult photoPickerResultWithData:imageData mimeType:mimeType image:imgT];
    
    NSString *filePath = @"";
    if([[option objectForKey:@"writeTempFile"] boolValue]) {
        // 文件后缀
        NSString *ext = [mimeType stringByReplacingOccurrencesOfString:@"image/" withString:@""];
        filePath = [self.compression persistFile:imageResult.imageData ext:ext];

        if (filePath == nil) {
            return nil;
        }
    }

    NSDictionary* exif = nil;
    if([[option objectForKey:@"includeExif"] boolValue]) {
        exif = [[CIImage imageWithData:imageData] properties];
    }
    
    imageResult.path = filePath;
    imageResult.exif = exif;
    imageResult.localIdentifier = phAsset.localIdentifier;
    imageResult.filename = [phAsset valueForKey:@"filename"];
    imageResult.data = [[option objectForKey:@"includeBase64"] boolValue] ? [imageResult.imageData base64EncodedStringWithOptions:0]: nil;
    imageResult.creationDate = phAsset.creationDate;
    imageResult.modificationDate = phAsset.modificationDate;
    return imageResult;
}

#pragma mark - getter

- (KPCompression *)compression
{
    if (_compression == nil) {
        _compression = [KPCompression sharedInstance];
    }
    return _compression;
}

@end
