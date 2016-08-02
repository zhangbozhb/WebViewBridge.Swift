#
#  Be sure to run `pod spec lint WebViewBridge.Swift.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#  pod trunk push WebViewBridge.Swift.podspec

Pod::Spec.new do |s|

  s.name         = "WebViewBridge.Swift"
  s.version      = "0.7"
  s.summary      = "A bridge for WebView(UIWebView, WKWebView), using JavaScriptCore, handles messages between native(Swift) and js"

  s.description  = <<-DESC
                    A bridge for WebView(UIWebView, WKWebView), using JavaScriptCore, handles messages between native(Swift) and js
                   DESC

  s.homepage     = "https://github.com/zhangbozhb/WebViewBridge.Swift"
  s.screenshots  = "https://github.com/zhangbozhb/WebViewBridge.Swift/blob/master/screenshots_1.gif"

  s.license      = { :type => "MIT"}
  
  s.author             = { "travel" => "zhangbozhb@gmail.com" }
  s.social_media_url   = "http://twitter.com/travel_zh"

  s.ios.deployment_target = "8.0"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/zhangbozhb/WebViewBridge.Swift.git", :tag => s.version }


  s.source_files  = ["Sources/*.swift", "Sources/*.js"]
  s.exclude_files = "Sources/Exclude"

end
