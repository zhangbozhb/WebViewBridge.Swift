#
#  Be sure to run `pod spec lint WebViewBridge.Swift.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  These will help people to find your library, and whilst it
  #  can feel like a chore to fill in it's definitely to your advantage. The
  #  summary should be tweet-length, and the description more in depth.
  #

  s.name         = "WebViewBridge.Swift"
  s.version      = "0.1"
  s.summary      = "A lightweight bridge for WebView and native code written in Swift."

  # This description is used to generate tags and improve search results.
  #   * Think: What does it do? Why did you write it? What is the focus?
  #   * Try to keep it short, snappy and to the point.
  #   * Write the description between the DESC delimiters below.
  #   * Finally, don't worry about the indent, CocoaPods strips it!
  s.description  = <<-DESC
                    A lightweight bridge for WebView and native code written in Swift, optimized for WKWebView
                   DESC

  s.homepage     = "https://github.com/zhangbozhb/WebViewBridge.Swift"
  s.screenshots  = "https://github.com/zhangbozhb/WebViewBridge.Swift/blob/master/screenshots_1.gif"


  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "travel" => "zhangbozhb@gmail.com" }
  s.social_media_url   = "http://twitter.com/travel_zh"

  s.ios.deployment_target = "8.0"
  # s.watchos.deployment_target = "2.0"
  # s.tvos.deployment_target = "9.0"

  s.source       = { :git => "https://github.com/zhangbozhb/WebViewBridge.Swift.git", :tag => "0.0.1" }


  s.source_files  = ["Sources/*.swift", "Sources/*.js"]
  s.exclude_files = "Sources/Exclude"

end
