//
//  KPImagePickerResult.m
//  react-native-kpframework-image-picker
//
//  Created by xukj on 2020/7/1.
//

#import "KPPickerResult.h"
#import <React/RCTUtils.h>

@implementation KPPickerResult

+ (instancetype)photoPickerResultWithData:(NSData *)imageData
                                 mimeType:(NSString *)mimeType
                                    image:(UIImage *)image
{
    KPPickerResult *result = [[KPPickerResult alloc] init];
    result.imageData = imageData;
    result.width = @(image.size.width);
    result.height = @(image.size.height);
    result.mime = mimeType;
    result.size = [NSNumber numberWithUnsignedInteger:imageData.length];
    result.image = image;
    return result;
}

+ (instancetype)photoPickerResultWithPath:(NSString *)path
                          localIdentifier:(NSString *)localIdentifier
                                 filename:(NSString *)filename
                                    width:(NSNumber *)width
                                   height:(NSNumber *)height
                                     size:(NSNumber *)size
                                     mime:(NSString *)mime
                                     exif:(NSDictionary *)exif
                                     data:(NSString *)data
                             creationDate:(NSDate *)creationDate
                         modificationDate:(NSDate *)modificationDate
{
    KPPickerResult *result = [[KPPickerResult alloc] init];
    result.path = path;
    result.exif = exif;
    result.localIdentifier = localIdentifier;
    result.filename = filename;
    result.width = width;
    result.height = height;
    result.mime = mime;
    result.size = size;
    result.data = data;
    result.creationDate = creationDate;
    result.modificationDate = modificationDate;
    return result;
}

+ (instancetype)videoPickerResultWithPath:(NSString *)path
                          localIdentifier:(NSString *)localIdentifier
                                 filename:(NSString *)filename
                                    width:(NSNumber *)width
                                   height:(NSNumber *)height
                                     size:(NSNumber *)size
                                sourceURL:(NSString *)sourceURL
                           coverImagePath:(NSString *)coverImagePath
{
    KPPickerResult *result = [[KPPickerResult alloc] init];
    result.path = path;
    result.localIdentifier = localIdentifier;
    result.filename = filename;
    result.width = width;
    result.height = height;
    result.mime = @"video/mp4";
    result.size = size;
    result.sourceURL = sourceURL;
    result.coverImagePath = coverImagePath;
    return result;
}

- (NSDictionary *)toJSON
{
    return @{
        @"path": (self.path && ![self.path isEqualToString:(@"")]) ? self.path : [NSNull null],
        @"sourceURL": RCTNullIfNil(self.sourceURL),
        @"localIdentifier": RCTNullIfNil(self.localIdentifier),
        @"filename": RCTNullIfNil(self.filename),
        @"width": RCTNullIfNil(self.width),
        @"height": RCTNullIfNil(self.height),
        @"mime": RCTNullIfNil(self.mime),
        @"size": RCTNullIfNil(self.size),
        @"data": RCTNullIfNil(self.data),
        @"exif": RCTNullIfNil(self.exif),
        @"coverImagePath": RCTNullIfNil(self.coverImagePath),
        @"creationDate": (self.creationDate) ? [@([self.creationDate timeIntervalSince1970]) stringValue] : [NSNull null],
        @"modificationDate": (self.modificationDate) ? [@([self.modificationDate timeIntervalSince1970]) stringValue] : [NSNull null],
    };
}

@end
