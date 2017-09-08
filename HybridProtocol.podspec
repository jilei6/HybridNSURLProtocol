#
#  Be sure to run `pod spec lint HybridProtocol.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|



  s.name         = "HybridProtocol"
  s.version      = "0.0.1"
  s.summary      = "A short description of HybridProtocol."
  s.description  = <<-DESC
                   DESC

  s.homepage     = "https://github.com/jilei6/HybridProtocol"
  s.license      = "MIT"
  s.author             = { "consins" => "consins@cubee.com" }
  s.platform     = :ios
  s.source       = { :git => "https://github.com/jilei6/HybridNSURLProtocol.git", :tag => "#{s.version}" }

    # UIView 和 EasyLog 在工程中以子目录显示
    s.subspec 'protrol' do |ss|
    ss.source_files = 'HybridNSURLProtocol/protrol/*.{h,m}'
    end

    s.subspec 'wkwebview' do |ss|
    ss.source_files = 'HybridNSURLProtocol/wkwebview/*.{h,m}'
end
end
