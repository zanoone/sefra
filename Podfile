# Podfile for SefraiOS

platform :ios, '14.0'

target 'SefraiOS' do
  use_frameworks!

  # Firebase - Privacy Manifest 완전 지원 버전 (Xcode 16 호환)
  pod 'Firebase/Core', '~> 11.5'
  pod 'Firebase/Messaging', '~> 11.5'
  pod 'Firebase/Analytics', '~> 11.5'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end
