//
//  KPPhotoPicker.h
//  react-native-kpframework-image-picker
//
//  Created by xukj on 2020/7/1.
//

#import <Foundation/Foundation.h>
#import <Photos/PHAsset.h>
#import "KPPickerResult.h"

typedef void(^KPPhotoPickerResultCompletion)(KPPickerResult *result);
typedef void(^KPPhotoPickerResultFail)(NSError *error);

@interface KPPhotoPicker : NSObject

- (KPPickerResult *)getOriginalPhoto:(PHAsset *)phAsset
                           imageData:(NSData *)imageData
                             dataUTI:(NSString *)dataUTI
                         orientation:(UIImageOrientation)orientation
                                info:(NSDictionary *)info
                              option:(NSDictionary *)option;

- (KPPickerResult *)getCompressPhoto:(PHAsset *)phAsset
                               image:(UIImage *)image
                              option:(NSDictionary *)option;

@end
