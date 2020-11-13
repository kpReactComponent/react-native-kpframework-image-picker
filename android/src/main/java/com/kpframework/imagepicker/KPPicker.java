package com.kpframework.imagepicker;

import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Base64;
import android.util.Log;

import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReadableMap;
import com.luck.picture.lib.PictureSelector;
import com.luck.picture.lib.config.PictureConfig;
import com.luck.picture.lib.config.PictureMimeType;
import com.luck.picture.lib.entity.LocalMedia;
import com.luck.picture.lib.listener.OnResultCallbackListener;
import com.luck.picture.lib.tools.SdkVersionUtils;

import org.jetbrains.annotations.NotNull;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.util.List;

public class KPPicker implements OnResultCallbackListener<LocalMedia> {
    private static final String TAG = "KPPhotoPicker";

    private ReadableMap mOption;

    private String mediaType = "any";
    private boolean multiple = false;
    private int maxFiles = 9;
    private int minFiles = 1;
    private int compressImageMaxWidth = 600;
    private double compressImageQuality = 0.8;
    private boolean includeBase64 = false;
    private boolean includeExif = false;
    private boolean cropping = false;
    private int cropWidth = 400;
    private int cropHeight = 400;
    private boolean cropperCircleOverlay = false;
    private int cropRadius = 200;
    private boolean writeTempFile = true;
    private boolean showCamera = true;

    private ReactContext mContext = null;
    private final ResultCollector mResultCollector = new ResultCollector();
    private final Compression mCompress = new Compression();

    public KPPicker(ReactContext context) {
        super();
        mContext = context;
    }

    public void setConfiguration(final ReadableMap options) {
        mOption = options;

        mediaType = options.hasKey("mediaType") ? options.getString("mediaType") : "any";
        multiple = options.hasKey("multiple") && options.getBoolean("multiple");
        maxFiles = options.hasKey("maxFiles") ? options.getInt("maxFiles") : 9;
        minFiles = options.hasKey("minFiles") ? options.getInt("minFiles") : 1;
        compressImageMaxWidth = options.hasKey("compressImageMaxWidth") ? options.getInt("compressImageMaxWidth") : 600;
        compressImageQuality = options.hasKey("compressImageQuality") ? options.getDouble("compressImageQuality") : 0.8;
        includeBase64 = options.hasKey("includeBase64") && options.getBoolean("includeBase64");
        includeExif = options.hasKey("includeExif") && options.getBoolean("includeExif");
        cropping = options.hasKey("cropping") && options.getBoolean("cropping");
        cropWidth = options.hasKey("cropWidth") ? options.getInt("cropWidth") : 400;
        cropHeight = options.hasKey("cropHeight") ? options.getInt("cropHeight") : 400;
        cropperCircleOverlay = options.hasKey("cropperCircleOverlay") && options.getBoolean("cropperCircleOverlay");
        cropRadius = options.hasKey("cropRadius") ? options.getInt("cropRadius") : 200;
        writeTempFile = options.hasKey("writeTempFile") && options.getBoolean("writeTempFile");
        showCamera = options.hasKey("showCamera") && options.getBoolean("showCamera");
    }

    /**
     * 开启相册
     * @param activity
     * @param promise
     */
    public void openPicker(final Activity activity, final Promise promise) {
        if (activity == null) {
            promise.reject(KPConstant.E_ACTIVITY_DOES_NOT_EXIST, "Activity doesn't exist");
            return;
        }

        int mimType = PictureMimeType.ofAll();
        if (mediaType.equals("video")){
            mimType = PictureMimeType.ofVideo();
            multiple = false; // 视频不支持多选
        }
        else if (mediaType.equals("photo")) mimType = PictureMimeType.ofImage();

        if (cropping) {
            mimType = PictureMimeType.ofImage();
            multiple = false; // 裁剪不支持多选
        }

        mResultCollector.setup(promise, true);

        // 进入相册 以下是例子：不需要的api可以不写
        PictureSelector.create(activity)
                .openGallery(mimType)// 全部.PictureMimeType.ofAll()、图片.ofImage()、视频.ofVideo()、音频.ofAudio()
                .imageEngine(GlideEngine.createGlideEngine())// 外部传入图片加载引擎，必传项
                .theme(R.style.picture_WeChat_style)// 主题样式设置 具体参考 values/styles   用法：R.style.picture.white.style v2.3.3后 建议使用setPictureStyle()动态方式
                .isWeChatStyle(true)// 是否开启微信图片选择风格
                .isUseCustomCamera(true)// 是否使用自定义相机
//                .setLanguage(language)// 设置语言，默认中文
//                .isPageStrategy(cbPage.isChecked())// 是否开启分页策略 & 每页多少条；默认开启
//                .setPictureStyle(mPictureParameterStyle)// 动态自定义相册主题
//                .setPictureCropStyle(mCropParameterStyle)// 动态自定义裁剪主题
//                .setPictureWindowAnimationStyle(mWindowAnimationStyle)// 自定义相册启动退出动画
//                .setRecyclerAnimationMode(animationMode)// 列表动画效果
                .isWithVideoImage(false)// 图片和视频是否可以同选,只在ofAll模式下有效
//                .isMaxSelectEnabledMask(cbEnabledMask.isChecked())// 选择数到了最大阀值列表是否启用蒙层效果
                //.isAutomaticTitleRecyclerTop(false)// 连续点击标题栏RecyclerView是否自动回到顶部,默认true
                //.loadCacheResourcesCallback(GlideCacheEngine.createCacheEngine())// 获取图片资源缓存，主要是解决华为10部分机型在拷贝文件过多时会出现卡的问题，这里可以判断只在会出现一直转圈问题机型上使用
                //.setOutputCameraPath()// 自定义相机输出目录，只针对Android Q以下，例如 Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM) +  File.separator + "Camera" + File.separator;
                //.setButtonFeatures(CustomCameraView.BUTTON_STATE_BOTH)// 设置自定义相机按钮状态
                .maxSelectNum(maxFiles)// 最大图片选择数量
                .minSelectNum(minFiles)// 最小选择数量
                .maxVideoSelectNum(1) // 视频最大选择数量
                //.minVideoSelectNum(1)// 视频最小选择数量
                //.closeAndroidQChangeVideoWH(!SdkVersionUtils.checkedAndroid_Q())// 关闭在AndroidQ下获取图片或视频宽高相反自动转换
                .imageSpanCount(4)// 每行显示个数
                .isReturnEmpty(false)// 未选择数据时点击按钮是否可以返回
                .closeAndroidQChangeWH(true)//如果图片有旋转角度则对换宽高,默认为true
                .closeAndroidQChangeVideoWH(!SdkVersionUtils.checkedAndroid_Q())// 如果视频有旋转角度则对换宽高,默认为false
                //.isAndroidQTransform(false)// 是否需要处理Android Q 拷贝至应用沙盒的操作，只针对compress(false); && .isEnableCrop(false);有效,默认处理
                .setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED)// 设置相册Activity方向，不设置默认使用系统
                .isOriginalImageControl(true)// 是否显示原图控制按钮，如果设置为true则用户可以自由选择是否使用原图，压缩、裁剪功能将会失效
                //.bindCustomPlayVideoCallback(new MyVideoSelectedPlayCallback(getContext()))// 自定义视频播放回调控制，用户可以使用自己的视频播放界面
                //.bindCustomPreviewCallback(new MyCustomPreviewInterfaceListener())// 自定义图片预览回调接口
                //.bindCustomCameraInterfaceListener(new MyCustomCameraInterfaceListener())// 提供给用户的一些额外的自定义操作回调
                //.cameraFileName(System.currentTimeMillis() +".jpg")    // 重命名拍照文件名、如果是相册拍照则内部会自动拼上当前时间戳防止重复，注意这个只在使用相机时可以使用，如果使用相机又开启了压缩或裁剪 需要配合压缩和裁剪文件名api
                //.renameCompressFile(System.currentTimeMillis() +".jpg")// 重命名压缩文件名、 如果是多张压缩则内部会自动拼上当前时间戳防止重复
                //.renameCropFileName(System.currentTimeMillis() + ".jpg")// 重命名裁剪文件名、 如果是多张裁剪则内部会自动拼上当前时间戳防止重复
                .selectionMode(multiple ? PictureConfig.MULTIPLE : PictureConfig.SINGLE)// 多选 or 单选
                .isSingleDirectReturn(true)// 单选模式下是否直接返回，PictureConfig.SINGLE模式下有效
                .isPreviewImage(true)// 是否可预览图片
                .isPreviewVideo(true)// 是否可预览视频
                //.querySpecifiedFormatSuffix(PictureMimeType.ofJPEG())// 查询指定后缀格式资源
//                .isEnablePreviewAudio(cb_preview_audio.isChecked()) // 是否可播放音频
                .isCamera(showCamera)// 是否显示拍照按钮
                //.isMultipleSkipCrop(false)// 多图裁剪时是否支持跳过，默认支持
                //.isMultipleRecyclerAnimation(false)// 多图裁剪底部列表显示动画效果
                .isZoomAnim(true)// 图片列表点击 缩放效果 默认true
                //.imageFormat(PictureMimeType.PNG)// 拍照保存图片格式后缀,默认jpeg,Android Q使用PictureMimeType.PNG_Q
                .isEnableCrop(cropping)// 是否裁剪
                //.basicUCropConfig()//对外提供所有UCropOptions参数配制，但如果PictureSelector原本支持设置的还是会使用原有的设置
                .isCompress(true)// 是否压缩
                .compressQuality((int)(compressImageQuality * 100))// 图片压缩后输出质量 0~ 100
                .synOrAsy(true)//同步true或异步false 压缩 默认同步
                //.queryMaxFileSize(10)// 只查多少M以内的图片、视频、音频  单位M
//                .compressSavePath(getPath())//压缩图片保存地址
                //.sizeMultiplier(0.5f)// glide 加载图片大小 0~1之间 如设置 .glideOverride()无效 注：已废弃
                //.glideOverride(160, 160)// glide 加载宽高，越小图片列表越流畅，但会影响列表图片浏览的清晰度 注：已废弃
//                .withAspectRatio(aspect_ratio_x, aspect_ratio_y)// 裁剪比例 如16:9 3:2 3:4 1:1 可自定义
//                .hideBottomControls(!cb_hide.isChecked())// 是否显示uCrop工具栏，默认不显示
                .isGif(true)// 是否显示gif图片
                .freeStyleCropEnabled(false)// 裁剪框是否可拖拽
                .circleDimmedLayer(cropperCircleOverlay)// 是否圆形裁剪
                //.setCropDimmedColor(ContextCompat.getColor(getContext(), R.color.app_color_white))// 设置裁剪背景色值
                //.setCircleDimmedBorderColor(ContextCompat.getColor(getApplicationContext(), R.color.app_color_white))// 设置圆形裁剪边框色值
                //.setCircleStrokeWidth(3)// 设置圆形裁剪边框粗细
                .showCropFrame(!cropperCircleOverlay)// 是否显示裁剪矩形边框 圆形裁剪时建议设为false
                .showCropGrid(!cropperCircleOverlay)// 是否显示裁剪矩形网格 圆形裁剪时建议设为false
                .isOpenClickSound(false)// 是否开启点击声音
//                .selectionData(mAdapter.getData())// 是否传入已选图片
                //.isDragFrame(false)// 是否可拖动裁剪框(固定)
                //.videoMinSecond(10)// 查询多少秒以内的视频
                //.videoMaxSecond(15)// 查询多少秒以内的视频
                //.recordVideoSecond(10)//录制视频秒数 默认60s
                //.isPreviewEggs(true)// 预览图片时 是否增强左右滑动图片体验(图片滑动一半即可看到上一张是否选中)
                //.cropCompressQuality(90)// 注：已废弃 改用cutOutQuality()
                //.cutOutQuality((int)(compressImageQuality * 100))// 裁剪输出质量 默认100
                .minimumCompressSize(100)// 小于多少kb的图片不压缩
                //.cropWH()// 裁剪宽高比，设置如果大于图片本身宽高则无效
                .cropImageWideHigh(cropWidth, cropHeight)// 裁剪宽高比，设置如果大于图片本身宽高则无效
                .rotateEnabled(false) // 裁剪是否可旋转图片
                //.scaleEnabled(false)// 裁剪是否可放大缩小图片
                //.videoQuality()// 视频录制质量 0 or 1
                //.forResult(PictureConfig.CHOOSE_REQUEST);//结果回调onActivityResult code
                .forResult(this);
    }

    /**
     * 开启相机
     * @param activity
     * @param promise
     */
    public void openCamera(final Activity activity, final Promise promise) {
        if (activity == null) {
            promise.reject(KPConstant.E_ACTIVITY_DOES_NOT_EXIST, "Activity doesn't exist");
            return;
        }

        int mimType = PictureMimeType.ofAll();
        if (mediaType.equals("video")){
            mimType = PictureMimeType.ofVideo();
            multiple = false; // 视频不支持多选
        }
        else if (mediaType.equals("photo")) mimType = PictureMimeType.ofImage();

        if (cropping) {
            mimType = PictureMimeType.ofImage();
            multiple = false; // 裁剪不支持多选
        }

        mResultCollector.setup(promise, true);

        // 进入相册 以下是例子：不需要的api可以不写
        PictureSelector.create(activity)
                .openCamera(mimType)// 全部.PictureMimeType.ofAll()、图片.ofImage()、视频.ofVideo()、音频.ofAudio()
                .imageEngine(GlideEngine.createGlideEngine())// 外部传入图片加载引擎，必传项
                .theme(R.style.picture_WeChat_style)// 主题样式设置 具体参考 values/styles   用法：R.style.picture.white.style v2.3.3后 建议使用setPictureStyle()动态方式
                .isWeChatStyle(true)// 是否开启微信图片选择风格
                .isUseCustomCamera(true)// 是否使用自定义相机
//                .setLanguage(language)// 设置语言，默认中文
//                .isPageStrategy(cbPage.isChecked())// 是否开启分页策略 & 每页多少条；默认开启
//                .setPictureStyle(mPictureParameterStyle)// 动态自定义相册主题
//                .setPictureCropStyle(mCropParameterStyle)// 动态自定义裁剪主题
//                .setPictureWindowAnimationStyle(mWindowAnimationStyle)// 自定义相册启动退出动画
//                .setRecyclerAnimationMode(animationMode)// 列表动画效果
                .isWithVideoImage(false)// 图片和视频是否可以同选,只在ofAll模式下有效
//                .isMaxSelectEnabledMask(cbEnabledMask.isChecked())// 选择数到了最大阀值列表是否启用蒙层效果
                //.isAutomaticTitleRecyclerTop(false)// 连续点击标题栏RecyclerView是否自动回到顶部,默认true
                //.loadCacheResourcesCallback(GlideCacheEngine.createCacheEngine())// 获取图片资源缓存，主要是解决华为10部分机型在拷贝文件过多时会出现卡的问题，这里可以判断只在会出现一直转圈问题机型上使用
                //.setOutputCameraPath()// 自定义相机输出目录，只针对Android Q以下，例如 Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DCIM) +  File.separator + "Camera" + File.separator;
                //.setButtonFeatures(CustomCameraView.BUTTON_STATE_BOTH)// 设置自定义相机按钮状态
                .maxSelectNum(maxFiles)// 最大图片选择数量
                .minSelectNum(minFiles)// 最小选择数量
                .maxVideoSelectNum(1) // 视频最大选择数量
                //.minVideoSelectNum(1)// 视频最小选择数量
                //.closeAndroidQChangeVideoWH(!SdkVersionUtils.checkedAndroid_Q())// 关闭在AndroidQ下获取图片或视频宽高相反自动转换
                .imageSpanCount(4)// 每行显示个数
                .isReturnEmpty(false)// 未选择数据时点击按钮是否可以返回
                .closeAndroidQChangeWH(true)//如果图片有旋转角度则对换宽高,默认为true
                .closeAndroidQChangeVideoWH(!SdkVersionUtils.checkedAndroid_Q())// 如果视频有旋转角度则对换宽高,默认为false
                //.isAndroidQTransform(false)// 是否需要处理Android Q 拷贝至应用沙盒的操作，只针对compress(false); && .isEnableCrop(false);有效,默认处理
                .setRequestedOrientation(ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED)// 设置相册Activity方向，不设置默认使用系统
                .isOriginalImageControl(true)// 是否显示原图控制按钮，如果设置为true则用户可以自由选择是否使用原图，压缩、裁剪功能将会失效
                //.bindCustomPlayVideoCallback(new MyVideoSelectedPlayCallback(getContext()))// 自定义视频播放回调控制，用户可以使用自己的视频播放界面
                //.bindCustomPreviewCallback(new MyCustomPreviewInterfaceListener())// 自定义图片预览回调接口
                //.bindCustomCameraInterfaceListener(new MyCustomCameraInterfaceListener())// 提供给用户的一些额外的自定义操作回调
                //.cameraFileName(System.currentTimeMillis() +".jpg")    // 重命名拍照文件名、如果是相册拍照则内部会自动拼上当前时间戳防止重复，注意这个只在使用相机时可以使用，如果使用相机又开启了压缩或裁剪 需要配合压缩和裁剪文件名api
                //.renameCompressFile(System.currentTimeMillis() +".jpg")// 重命名压缩文件名、 如果是多张压缩则内部会自动拼上当前时间戳防止重复
                //.renameCropFileName(System.currentTimeMillis() + ".jpg")// 重命名裁剪文件名、 如果是多张裁剪则内部会自动拼上当前时间戳防止重复
                .selectionMode(multiple ? PictureConfig.MULTIPLE : PictureConfig.SINGLE)// 多选 or 单选
                .isSingleDirectReturn(true)// 单选模式下是否直接返回，PictureConfig.SINGLE模式下有效
                .isPreviewImage(true)// 是否可预览图片
                .isPreviewVideo(true)// 是否可预览视频
                //.querySpecifiedFormatSuffix(PictureMimeType.ofJPEG())// 查询指定后缀格式资源
//                .isEnablePreviewAudio(cb_preview_audio.isChecked()) // 是否可播放音频
                .isCamera(showCamera)// 是否显示拍照按钮
                //.isMultipleSkipCrop(false)// 多图裁剪时是否支持跳过，默认支持
                //.isMultipleRecyclerAnimation(false)// 多图裁剪底部列表显示动画效果
                .isZoomAnim(true)// 图片列表点击 缩放效果 默认true
                //.imageFormat(PictureMimeType.PNG)// 拍照保存图片格式后缀,默认jpeg,Android Q使用PictureMimeType.PNG_Q
                .isEnableCrop(cropping)// 是否裁剪
                //.basicUCropConfig()//对外提供所有UCropOptions参数配制，但如果PictureSelector原本支持设置的还是会使用原有的设置
                .isCompress(true)// 是否压缩
                .compressQuality((int)(compressImageQuality * 100))// 图片压缩后输出质量 0~ 100
                .synOrAsy(true)//同步true或异步false 压缩 默认同步
                //.queryMaxFileSize(10)// 只查多少M以内的图片、视频、音频  单位M
//                .compressSavePath(getPath())//压缩图片保存地址
                //.sizeMultiplier(0.5f)// glide 加载图片大小 0~1之间 如设置 .glideOverride()无效 注：已废弃
                //.glideOverride(160, 160)// glide 加载宽高，越小图片列表越流畅，但会影响列表图片浏览的清晰度 注：已废弃
//                .withAspectRatio(aspect_ratio_x, aspect_ratio_y)// 裁剪比例 如16:9 3:2 3:4 1:1 可自定义
//                .hideBottomControls(!cb_hide.isChecked())// 是否显示uCrop工具栏，默认不显示
                .isGif(true)// 是否显示gif图片
                .freeStyleCropEnabled(false)// 裁剪框是否可拖拽
                .circleDimmedLayer(cropperCircleOverlay)// 是否圆形裁剪
                //.setCropDimmedColor(ContextCompat.getColor(getContext(), R.color.app_color_white))// 设置裁剪背景色值
                //.setCircleDimmedBorderColor(ContextCompat.getColor(getApplicationContext(), R.color.app_color_white))// 设置圆形裁剪边框色值
                //.setCircleStrokeWidth(3)// 设置圆形裁剪边框粗细
                .showCropFrame(!cropperCircleOverlay)// 是否显示裁剪矩形边框 圆形裁剪时建议设为false
                .showCropGrid(!cropperCircleOverlay)// 是否显示裁剪矩形网格 圆形裁剪时建议设为false
                .isOpenClickSound(false)// 是否开启点击声音
//                .selectionData(mAdapter.getData())// 是否传入已选图片
                //.isDragFrame(false)// 是否可拖动裁剪框(固定)
                //.videoMinSecond(10)// 查询多少秒以内的视频
                //.videoMaxSecond(15)// 查询多少秒以内的视频
                //.recordVideoSecond(10)//录制视频秒数 默认60s
                //.isPreviewEggs(true)// 预览图片时 是否增强左右滑动图片体验(图片滑动一半即可看到上一张是否选中)
                //.cropCompressQuality(90)// 注：已废弃 改用cutOutQuality()
                //.cutOutQuality((int)(compressImageQuality * 100))// 裁剪输出质量 默认100
                .minimumCompressSize(100)// 小于多少kb的图片不压缩
                //.cropWH()// 裁剪宽高比，设置如果大于图片本身宽高则无效
                .cropImageWideHigh(cropWidth, cropHeight)// 裁剪宽高比，设置如果大于图片本身宽高则无效
                .rotateEnabled(false) // 裁剪是否可旋转图片
                //.scaleEnabled(false)// 裁剪是否可放大缩小图片
                //.videoQuality()// 视频录制质量 0 or 1
                //.forResult(PictureConfig.CHOOSE_REQUEST);//结果回调onActivityResult code
                .forResult(this);
    }

    @Override
    public void onResult(@NotNull List<LocalMedia> result) {
        mResultCollector.setWaitCount(result.size());
        for (LocalMedia media : result) {
            Log.i(TAG, "是否压缩:" + media.isCompressed());
            Log.i(TAG, "压缩:" + media.getCompressPath());
            Log.i(TAG, "原图:" + media.getPath());
            Log.i(TAG, "是否裁剪:" + media.isCut());
            Log.i(TAG, "裁剪:" + media.getCutPath());
            Log.i(TAG, "是否开启原图:" + media.isOriginal());
            Log.i(TAG, "原图路径:" + media.getOriginalPath());
            Log.i(TAG, "Android Q 特有Path:" + media.getAndroidQToPath());
            Log.i(TAG, "宽高: " + media.getWidth() + "x" + media.getHeight());
            Log.i(TAG, "Size: " + media.getSize());
            // TODO 可以通过PictureSelectorExternalUtils.getExifInterface();方法获取一些额外的资源信息，如旋转角度、经纬度等信息


            try {
                KPPickerResult check = new KPPickerResult();
                check.setMime(media.getMimeType());

                if (check.isPhoto()) {
                    KPPickerResult pickerResult = pickPhoto(media);
                    mResultCollector.notifySuccess(pickerResult.toJSON());
                }
                else if (check.isVideo()) {
                    KPPickerResult pickerResult = pickVideo(media);
                    mResultCollector.notifySuccess(pickerResult.toJSON());
                }

                // 其他的类型不处理

            } catch (Exception ex) {
                mResultCollector.notifyProblem(KPConstant.E_NO_IMAGE_DATA_FOUND, ex.getMessage());
            }
        }
    }

    @Override
    public void onCancel() {
        mResultCollector.notifyProblem(KPConstant.E_PICKER_CANCELLED_KEY, KPConstant.E_PICKER_CANCELLED_MSG);
    }


    /**
     * 选择的是图片
     * @param media
     * @throws Exception
     */
    public KPPickerResult pickPhoto(LocalMedia media) throws Exception {
        KPPickerResult result = new KPPickerResult();

        String path = media.getCompressPath();
        if (media.isOriginal()) path = media.getOriginalPath();
        else if (media.isCut()) path = media.getCutPath();
        result.setPath(path);

        if (media.getPath() != null) {
            result.setSourceURL(media.getPath());
        }
        result.setFilename(RealPathUtil.getFilename(path));
        result.setMime(media.getMimeType());

        if (media.isOriginal()) {
            result.setWidth(media.getWidth());
            result.setHeight(media.getHeight());
        }
        else {
            BitmapFactory.Options options = validateImage(path);
            result.setWidth(options.outWidth);
            result.setHeight(options.outHeight);
        }

        if (includeBase64) {
            result.setData(getBase64StringFromFile(path));
        }

        if (includeExif) {
            result.setExif(ExifExtractor.extract(path));
        }

        return result;
    }

    /**
     * 选择的是视频
     * @param media
     * @throws Exception
     */
    public KPPickerResult pickVideo(LocalMedia media) {
        KPPickerResult result = new KPPickerResult();
        result.setPath(media.getPath());
        result.setSourceURL(media.getPath());
        result.setMime(media.getMimeType());
        result.setWidth(media.getWidth());
        result.setHeight(media.getHeight());
        return result;
    }

    // 图片压缩
    // ---

    //    private void getAsyncSelection(final Activity activity, Uri uri, boolean isCamera) throws Exception {
//        String path = resolveRealPath(activity, uri, isCamera);
//        if (path == null || path.isEmpty()) {
//            mResultCollector.notifyProblem(KPConstant.E_NO_IMAGE_DATA_FOUND, "Cannot resolve asset path.");
//            return;
//        }
//
//        String mime = getMimeType(path);
//        if (mime != null && mime.startsWith("video/")) {
//            getVideo(activity, path, mime);
//            return;
//        }
//
//        mResultCollector.notifySuccess(getImage(activity, path));
//    }
//
//    private String resolveRealPath(Activity activity, Uri uri, boolean isCamera) throws IOException {
//        String path;
//
//        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) {
//            path = RealPathUtil.getRealPathFromURI(activity, uri);
//        } else {
//            if (isCamera) {
//                Uri mediaUri = Uri.parse(mCurrentMediaPath);
//                path = mediaUri.getPath();
//            } else {
//                path = RealPathUtil.getRealPathFromURI(activity, uri);
//            }
//        }
//
//        return path;
//    }
//
//    private WritableMap getImage(final String path) throws Exception {
//        WritableMap image = new WritableNativeMap();
//
//        if (path.startsWith("http://") || path.startsWith("https://")) {
//            throw new Exception("Cannot select remote files");
//        }
//        BitmapFactory.Options original = validateImage(path);
//
//        // if compression options are provided image will be compressed. If none options is provided,
//        // then original image will be returned
//        File compressedImage = mCompress.compressImage(mContext, mOption, path, original);
//        String compressedImagePath = compressedImage.getPath();
//        BitmapFactory.Options options = validateImage(compressedImagePath);
//        long modificationDate = new File(path).lastModified();
//
//        image.putString("path", "file://" + compressedImagePath);
//        image.putInt("width", options.outWidth);
//        image.putInt("height", options.outHeight);
//        image.putString("mime", options.outMimeType);
//        image.putInt("size", (int) new File(compressedImagePath).length());
//        image.putString("modificationDate", String.valueOf(modificationDate));
//
//        if (includeBase64) {
//            image.putString("data", getBase64StringFromFile(compressedImagePath));
//        }
//
//        if (includeExif) {
//            try {
//                WritableMap exif = ExifExtractor.extract(path);
//                image.putMap("exif", exif);
//            } catch (Exception ex) {
//                ex.printStackTrace();
//            }
//        }
//
//        return image;
//    }
//
//    private File createImageFile() throws IOException {
//
//        String imageFileName = "image-" + UUID.randomUUID().toString();
//        File path = mContext.getExternalFilesDir(Environment.DIRECTORY_PICTURES);
//
//        if (!path.exists() && !path.isDirectory()) {
//            path.mkdirs();
//        }
//
//        File image = File.createTempFile(imageFileName, ".jpg", path);
//
//        // Save a file: path for use with ACTION_VIEW intents
//        mCurrentMediaPath = "file:" + image.getAbsolutePath();
//
//        return image;
//
//    }
//
    private String getBase64StringFromFile(String absoluteFilePath) {
        InputStream inputStream;

        try {
            inputStream = new FileInputStream(new File(absoluteFilePath));
        } catch (FileNotFoundException e) {
            e.printStackTrace();
            return null;
        }

        byte[] bytes;
        byte[] buffer = new byte[8192];
        int bytesRead;
        ByteArrayOutputStream output = new ByteArrayOutputStream();

        try {
            while ((bytesRead = inputStream.read(buffer)) != -1) {
                output.write(buffer, 0, bytesRead);
            }
        } catch (IOException e) {
            e.printStackTrace();
        }

        bytes = output.toByteArray();
        return Base64.encodeToString(bytes, Base64.NO_WRAP);
    }

    private BitmapFactory.Options validateImage(String path) throws Exception {
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inJustDecodeBounds = true;
        options.inPreferredConfig = Bitmap.Config.RGB_565;
        options.inDither = true;

        BitmapFactory.decodeFile(path, options);

        if (options.outMimeType == null || options.outWidth == 0 || options.outHeight == 0) {
            throw new Exception("Invalid image selected");
        }
        return options;
    }
}
