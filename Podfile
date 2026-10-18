platform :ios, '14.0'
inhibit_all_warnings!

target 'MarketWatch' do
  use_frameworks!

  pod 'Alamofire', '~> 5.12'
  pod 'RxSwift', '~> 6.9'
  pod 'RxCocoa', '~> 6.9'

  target 'MarketWatchTests' do
    inherit! :search_paths

    pod 'RxTest', '~> 6.9'
    pod 'RxBlocking', '~> 6.9'
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end
  end
end
