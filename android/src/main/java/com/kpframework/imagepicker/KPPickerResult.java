package com.kpframework.imagepicker;

import android.graphics.BitmapFactory;

import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;

import java.io.File;

public class KPPickerResult {
    private String path;
    private String sourceURL;
    private String filename;
    private String mime = "";
    private long size = 0;
    private long sourceSize = 0;
    private int width;
    private int height;
    private String data;
    private WritableMap exif;

    public WritableMap toJSON() {
        WritableMap media = new WritableNativeMap();

        if (size > 0) {
            media.putString("path", "file://" + path);
            media.putDouble("size", size);
        }
        else {
            media.putString("path", null);
            media.putDouble("size", 0);
        }

        if (sourceSize > 0) {
            media.putString("sourceURL", "file://" + sourceURL);
            media.putDouble("sourceSize", sourceSize);
        }
        else {
            media.putString("sourceURL", null);
            media.putDouble("sourceSize", 0);
        }

        media.putString("filename", filename);
        media.putString("mime", mime);
        media.putDouble("width", width);
        media.putDouble("height", height);
        media.putString("data", data);
        media.putMap("exif", exif);

        if (isPhoto()) {
            media.putString("mediaType", "photo");
        }
        else if (isVideo()) {
            media.putString("mediaType", "video");
        }
        else {
            media.putString("mediaType", "other");
        }

        return media;
    }

    public boolean isVideo() {
        return mime.toLowerCase().contains("video");
    }

    public boolean isPhoto() {
        return mime.toLowerCase().contains("image");
    }

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
        File file = new File(path);
        size = file.exists() ? file.length() : 0;
    }

    public String getSourceURL() {
        return sourceURL;
    }

    public void setSourceURL(String sourceURL) {
        this.sourceURL = sourceURL;
        File file = new File(sourceURL);
        sourceSize = file.exists() ? file.length() : 0;
    }

    public String getFilename() {
        return filename;
    }

    public void setFilename(String filename) {
        this.filename = filename;
    }

    public String getMime() {
        return mime;
    }

    public void setMime(String mime) {
        this.mime = mime;
    }

    public long getSize() {
        return size;
    }

    public long getSourceSize() {
        return sourceSize;
    }

    public int getWidth() {
        return width;
    }

    public void setWidth(int width) {
        this.width = width;
    }

    public int getHeight() {
        return height;
    }

    public void setHeight(int height) {
        this.height = height;
    }

    public String getData() {
        return data;
    }

    public void setData(String data) {
        this.data = data;
    }

    public WritableMap getExif() {
        return exif;
    }

    public void setExif(WritableMap exif) {
        this.exif = exif;
    }
}
