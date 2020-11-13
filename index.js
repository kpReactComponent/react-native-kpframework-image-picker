/**
 * @author xukj
 * @date 2019/04/10
 * @description Gallery.ios
 */
import React from "react";
import { NativeModules } from "react-native";

const KPNativeImagePicker = NativeModules.KPNativeImagePicker;

function openPicker(config = {}) {
  return KPNativeImagePicker.openPicker(config);
}

function openCamera(config = {}) {
  return KPNativeImagePicker.openCamera(config);
}

function cleanSingle(path) {
  return KPNativeImagePicker.cleanSingle(path);
}

function cleanAll() {
  return KPNativeImagePicker.clean();
}

export default {
  openPicker,
  openCamera,
  cleanSingle,
  cleanAll,
};
