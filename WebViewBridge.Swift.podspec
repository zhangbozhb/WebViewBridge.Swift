#  pod spec lint WebViewBridge.Swift.podspec --allow-warnings
#  pod trunk push WebViewBridge.Swift.podspec --allow-warnings

Pod::Spec.new do |s|

  s.name         = "WebViewBridge.Swift"
  s.version      = "2.5"
  s.summary      = "A bridge for WebView(UIWebView, WKWebView), using JavaScriptCore, handles messages between native(Swift) and js"

  s.description  = <<-DESC
                    A bridge for WebView(UIWebView, WKWebView), using JavaScriptCore, handles messages between native(Swift) and js
                   DESC

  s.homepage     = "https://github.com/zhangbozhb/WebViewBridge.Swift"
  s.screenshots  = "https://github.com/zhangbozhb/WebViewBridge.Swift/blob/master/screenshots_1.gif"

  s.license      = { :type => "MIT"}
  
  s.author             = { "travel" => "zhangbozhb@gmail.com" }
  s.social_media_url   = "http://twitter.com/travel_zh"

  s.swift_version = '5'
  s.ios.deployment_target = "8.0"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/zhangbozhb/WebViewBridge.Swift.git", :tag => s.version }


  s.source_files  = ["WebViewBridge.Swift/Classes/*.swift", "WebViewBridge.Swift/Classes/*.js"]
end
