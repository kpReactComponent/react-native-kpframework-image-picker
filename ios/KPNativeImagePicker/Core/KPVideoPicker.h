//
//  KPVideoPicker.h
//  react-native-kpframework-image-picker
//
//  Created by xukj on 2020/7/1.
//

#import <Foundation/Foundation.h>
#import <Photos/PHAsset.h>
#import "KPPickerResult.h"

typedef void(^KPPickerResultCompletion)(KPPickerResult *result);

@interface KPVideoPicker : NSObject

- (void)getVideoAsset:(PHAsset*)forAsset
           coverImage:(UIImage *)coverImage
               option:(NSDictionary *)option
           completion:(KPPickerResultCompletion)completion;

@end
