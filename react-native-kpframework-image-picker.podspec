package = JSON.parse(File.read(File.join(__dir__, "package.json")))
version = package['version']
author = package['author']['name']
email = package['author']['email']
homepage = package['homepage']

Pod::Spec.new do |s|
  s.name             = "react-native-kpframework-image-picker"
  s.version          = version
  s.summary          = package["description"]
  s.requires_arc = true
  s.license      = 'MIT'
  s.homepage     = 'n/a'
  s.authors      = { author => email }
  s.source       = { :git => homepage, :tag => 'v#{version}'}
  s.source_files = 'ios/KPNativeImagePicker/**/*.{h,m}'
  s.private_header_files = 'ios/KPNativeImagePicker/Core/**/*.h'
  s.platform     = :ios, "8.0"
  s.dependency 'TZImagePickerController', '3.3.2'
  s.dependency 'React-Core'
end
