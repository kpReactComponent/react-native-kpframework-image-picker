# react-native-kpframework-image-picker

图片选择器。

## 原生库

- Android  
  基于[PictureSelector](https://github.com/LuckSiege/PictureSelector)修改
- iOS  
  基于[TZImagePickerController](https://github.com/banchichen/TZImagePickerController)修改

## 安装方式

#### 第一步: 添加库

```
yarn add react-native-kpframework-image-picker
```

#### 第二步: 链接原生 (rn 0.6x 以上版本略过)

```
react-native link react-native-kpframework-image-picker
```

#### 第三步

**android**  
Gradle >= 3.1.4 (android/build.gradle)  
Android SDK >= 26 (android/app/build.gradle)

build.gradle 修改

1. 在 build.gradle 的 buildscript 添加

```
maven { url 'https://jitpack.io' }
```

2. minSdkVersion 最低支持版本 **19**

3. 如果使用了**Glide**库，请升级到 v4

4. 支持 androidx，如果您的项目还没有支持 androidx，请先支持 androidx

**iOS**

1. Cocoapods(推荐)  
   修改 Podfile 文件，如下:

```ruby
platform :ios, '9.0'
require_relative '../node_modules/@react-native-community/cli-platform-ios/native_modules'

target 'Template' do
  # Pods for Demo61
  pod 'FBLazyVector', :path => "../node_modules/react-native/Libraries/FBLazyVector"
  pod 'FBReactNativeSpec', :path => "../node_modules/react-native/Libraries/FBReactNativeSpec"
  pod 'RCTRequired', :path => "../node_modules/react-native/Libraries/RCTRequired"
  pod 'RCTTypeSafety', :path => "../node_modules/react-native/Libraries/TypeSafety"
  pod 'React', :path => '../node_modules/react-native/'
  pod 'React-Core', :path => '../node_modules/react-native/'
  pod 'React-CoreModules', :path => '../node_modules/react-native/React/CoreModules'
  pod 'React-Core/DevSupport', :path => '../node_modules/react-native/'
  pod 'React-RCTActionSheet', :path => '../node_modules/react-native/Libraries/ActionSheetIOS'
  pod 'React-RCTAnimation', :path => '../node_modules/react-native/Libraries/NativeAnimation'
  pod 'React-RCTBlob', :path => '../node_modules/react-native/Libraries/Blob'
  pod 'React-RCTImage', :path => '../node_modules/react-native/Libraries/Image'
  pod 'React-RCTLinking', :path => '../node_modules/react-native/Libraries/LinkingIOS'
  pod 'React-RCTNetwork', :path => '../node_modules/react-native/Libraries/Network'
  pod 'React-RCTSettings', :path => '../node_modules/react-native/Libraries/Settings'
  pod 'React-RCTText', :path => '../node_modules/react-native/Libraries/Text'
  pod 'React-RCTVibration', :path => '../node_modules/react-native/Libraries/Vibration'
  pod 'React-Core/RCTWebSocket', :path => '../node_modules/react-native/'

  pod 'React-cxxreact', :path => '../node_modules/react-native/ReactCommon/cxxreact'
  pod 'React-jsi', :path => '../node_modules/react-native/ReactCommon/jsi'
  pod 'React-jsiexecutor', :path => '../node_modules/react-native/ReactCommon/jsiexecutor'
  pod 'React-jsinspector', :path => '../node_modules/react-native/ReactCommon/jsinspector'
  pod 'ReactCommon/jscallinvoker', :path => "../node_modules/react-native/ReactCommon"
  pod 'ReactCommon/turbomodule/core', :path => "../node_modules/react-native/ReactCommon"
  pod 'Yoga', :path => '../node_modules/react-native/ReactCommon/yoga'

  pod 'DoubleConversion', :podspec => '../node_modules/react-native/third-party-podspecs/DoubleConversion.podspec'
  pod 'glog', :podspec => '../node_modules/react-native/third-party-podspecs/glog.podspec'
  pod 'Folly', :podspec => '../node_modules/react-native/third-party-podspecs/Folly.podspec'

  # 0.6x版本不需要添加
  # pod 'react-native-kpframework-image-picker', :podspec => '../node_modules/react-native/react-native-kpframework-image-picker/react-native-kpframework-image-picker.podspec'

  use_native_modules!
end

install! 'cocoapods', :deterministic_uuids => false
```

执行 `pod install`

2. 手动安装  
   Click on project General tab  
   Under Deployment Info set Deployment Target to 9.0  
   Under Embedded Binaries click + and add react-native-kpframework-image-picker.framework

## 使用

```jsx
import KPImagePicker from 'react-native-kpframework-image-picker';
...

KPImagePicker.openPicker().then(value => {

}).catch(error => {

});

```

## API

- openPicker(options);

### 1. options 参数说明

| 属性                     | 类型   | 默认值          | 说明                                                                                                                    |
| ------------------------ | ------ | --------------- | ----------------------------------------------------------------------------------------------------------------------- |
| mediaType                | string | 'any'           | 选择的文件类型`photo` `video` `any`                                                                                     |
| multiple                 | bool   | false           | 是否支持多选                                                                                                            |
| maxFiles                 | number | 9               | 最多选择的文件数(多选时生效)                                                                                            |
| minFiles                 | number | 1               | 最少选择的文件数(多选时生效)                                                                                            |
| compressImageMaxWidth(ios)    | number | 600(px)         | 图片文件压缩大小(根据宽度按比例压缩)如果选择原图，则不会裁剪和压缩                                                      |
| compressImageQuality     | number | 0.8             | 图片文件压缩质量                                                                                                        |
| compressVideoPreset(ios) | string | 'MediumQuality' | 视频文件压缩质量 `640x480` `960x540` `1280x720` `1920x1080` `LowQuality` `MediumQuality` `HighestQuality` `Passthrough` |
| includeBase64            | bool   | false           | 返回图片 data 的 base64 值                                                                                              |
| includeExif              | bool   | false           | 返回 image exif 信息                                                                                                    |
| cropping                 | bool   | false           | 裁剪功能开关                                                                                                            |
| cropWidth                | number | 400(px)         | 裁剪图片宽(如果超过原图高宽，则无效)度                                                                                                            |
| cropHeight               | number | 400(px)         | 裁剪图片高(如果超过原图高宽，则无效)度                                                                                                            |
| cropperCircleOverlay     | bool   | false           | 圆形裁剪框                                                                                                              |
| cropRadius(ios)               | number | 200(px)         | 圆形裁剪图片半径                                                                                                        |
| writeTempFile(ios)       | bool   | true            | 裁剪、压缩时生成临时文件                                                                                                |
| showCamera               | bool   | true            | 是否在相册中支持拍照功能                                                                                                |

### 4. 其他说明

### 5. 注意事项

## TODO

- 返回结果需要统一数组还是单个对象
- android 端集成
