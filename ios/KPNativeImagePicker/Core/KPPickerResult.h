//
//  KPImagePickerResult.h
//  react-native-kpframework-image-picker
//
//  Created by xukj on 2020/7/1.
//

#import <Foundation/Foundation.h>

@interface KPPickerResult : NSObject

@property (nonatomic, strong) NSString *path;
@property (nonatomic, strong) NSString *localIdentifier;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSNumber *width;
@property (nonatomic, strong) NSNumber *height;
@property (nonatomic, strong) NSNumber *size;
@property (nonatomic, strong) NSString *mime;

// 图片文件时有效
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSData *imageData;
@property (nonatomic, strong) NSString *data;
@property (nonatomic, strong) NSDictionary *exif;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSDate *modificationDate;

// 视频文件时有效
@property (nonatomic, strong) NSString *sourceURL;
@property (nonatomic, strong) NSString *coverImagePath;

+ (instancetype)photoPickerResultWithData:(NSData *)imageData
                                 mimeType:(NSString *)mimeType
                                    image:(UIImage *)image;

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
                         modificationDate:(NSDate *)modificationDate;

+ (instancetype)videoPickerResultWithPath:(NSString *)path
                          localIdentifier:(NSString *)localIdentifier
                                 filename:(NSString *)filename
                                    width:(NSNumber *)width
                                   height:(NSNumber *)height
                                     size:(NSNumber *)size
                                sourceURL:(NSString *)sourceURL
                           coverImagePath:(NSString *)coverImagePath;

- (NSDictionary *)toJSON;

@end
