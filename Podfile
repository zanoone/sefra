# Podfile for SefraiOS

platform :ios, '14.0'

target 'SefraiOS' do
  use_frameworks!

  # Firebase - Privacy Manifest 포함 버전
  pod 'Firebase/Core', '10.18.0'
  pod 'Firebase/Messaging', '10.18.0'
  pod 'Firebase/Analytics', '10.18.0'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end
