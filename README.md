# WebViewBridge.Swift


[![Language: Swift 2](https://img.shields.io/badge/language-swift2-f48041.svg?style=flat)](https://developer.apple.com/swift)
![Platform: iOS 8+](https://img.shields.io/badge/platform-iOS%208%2B-blue.svg?style=flat)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Cocoapods compatible](https://img.shields.io/badge/Cocoapods-compatible-4BC51D.svg?style=flat)](https://cocoapods.org)
[![License: MIT](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://github.com/jiecao-fm/SwiftTheme/blob/master/LICENSE)


A lightweight bridge for WebView and native code written in Swift.
Bridge is not a new topic, there are existing awesome projects, <a herf="https://github.com/apache/Cordova-ios">Cordova(PhoneGap)</a>, <a herf="https://github.com/marcuswestin/WebViewJavascriptBridge">WebViewJavascriptBridge</a> and so on.
Cordova(PhoneGap) is a great project and cross platform, well tested. However if we do not want to develop hybrid app, it seems kind of too complex and hard to integrate to our app.
WebViewJavascriptBridge is simple and have both iOS and android version. However it has no Swift version and does not make new feature of WKWebView.
If you just want to integrate bridge feature to you app, WebViewBridge.Swift supplies you another choice. It's brief, simple but works well.

If your have any question, you can email me(zhangbozhb@gmail.com) or leave message.

## Requirements

* iOS 8.0+
* Xcode 7.0 or above


###ScreenShots
![WebViewBridge.Swift](https://github.com/zhangbozhb/WebViewBridge.Swift/blob/master/screenshots_1.gif)

## Usage


#### Set up bridge between your webView and html

**1** Inject Bridge Js to your html
    - UIWebView: Copy bridge_code.js to your html, or refer bridge_core.js in html header.
    - WKWebView: You do not need to do anything.

**2** Set up bridge for your UIWebView/WKWebView
```swift
let webView = WKWebView()
let bridge = ZHWebViewBridge.bridge(webView)
```

**3** For WKWebView you do nothing. As for UIWebView your should call bridge.handleRequest(request) in webView:shouldStartLoadWithRequest:navigationType: of UIWebViewDelegate
```swift
func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return !bridge.handleRequest(request)
    }
```

* Note:
    - WKWebView: step 2 is enough. If you will reset your webView.configuration.userContentController,
     your should do step 2 after that, or else bridge will not work.
    - UIWebView: step 1, 2, 3 is required.


### Native JS code Interaction

#### 1, Native call js handler

**a**, write js handler in you html or you business js
```javascript
ZHWVBridge.Core.registerJsHandler(
          "Device.updateAppVersion",
          function (version) {
            document.getElementById("native-version-container").textContent = version;
            return "js get version: " + version;
          });
```

* Note: ZHWVBridge.Core.registerJsHandler(handlerName, callback)

**b**, call js handler from native
```swift
bridge.callJsHandler(
            "Device.updateAppVersion",
            args: ["1.2"],
            callback: { (data:AnyObject?) in
                // here data should be "js get version: 1.2"
                ...
        })
```
* Note: bridge.callJsHandler(handlerName, argArrayPassToJs, callback)

#### 2, Js call Native handler

**a**, write and register native handler to bridge
```swift
bridge.registerHandler("Image.updatePlaceHolder") { (args:[AnyObject]) -> (Bool, [AnyObject]?) in
            return (true, ["place_holder.png"])
        }
```

**b**, call from js
```javascript
ZHWVBridge.Core.callNativeHandler(
            "Image.updatePlaceHolder",
            [],
            function(placeHolder) {
              var items = document.getElementsByTagName('img');
              for (var i = 0, count = items.length; i < count; ++i) {
                var item = items[i];
                if (item.src.toLocaleLowerCase() == "file:///default_cover") {
                  item.src = placeHolder;
                }
              }
            });
```

* Note: ZHWVBridge.Core.callNativeHandler(handlerName, argArrayPassToNativeHandler, successCallback, failCallback)


## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

``` bash
$ gem install cocoapods
```

To integrate ChameleonSwift into your Xcode project using CocoaPods, specify it in your `Podfile`:

``` ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'WebViewBridge.Swift'
```

Then, run the following command:

``` bash
$ pod install
```

You should open the `{Project}.xcworkspace` instead of the `{Project}.xcodeproj` after you installed anything from CocoaPods.


### Carthage
```bash
github "zhangbozhb/WebViewBridge.Swift"
```



# WebViewBridge.Swift 介绍
WebViewBridge.Swift 封装了WebView js 和 Native代码的调用.
WebView与Native桥并不是一个新的话题, 在很早以前就有实现了, 也有很好的实现.
比如 <a herf="https://github.com/apache/Cordova-ios">Cordova(PhoneGap)</a>, <a herf="https://github.com/marcuswestin/WebViewJavascriptBridge">WebViewJavascriptBridge</a>
桥本身的技术并不困难, 实现也都大同小异, 既然已经有项目 <a herf="https://github.com/apache/Cordova-ios">Cordova(PhoneGap)</a>, <a herf="https://github.com/marcuswestin/WebViewJavascriptBridge">WebViewJavascriptBridge</a>, 那还有必要重复再造轮子么?
- Cordova-ios: 本身是一个很了不起的项目, 提供了多个平台, 对于 Hybrid App而言, 是一个很好的选择;
如果你编写的不是Hybrid App, 只是想简单的集成 bridge这个功能, Cordova 就显得过于复杂了, 不方面集成, 另外暂时也无 swift 版本的
- WebViewJavascriptBridge: 也很不错, 同时提供了 iOS, android 版本, 集成也简单方便.
 当然不足之处也比较明显, 一方面没有利用WKWebView的新特性,另一方面页没有提供Swift版本.

WebViewBridge.Swift 的初衷并不是替换谁, 只是给你提供了另一种可能. WebViewBridge.Swift 本身使用简单, 纯 Swift实现, 利用了WKWebView的新的特性;
如果你只是想给你的 APP 添加 bridge这个功能, WebViewBridge.Swift 是你的一个不错的选择.

此外: 对于此外常见的 webview点击下载图片, 实例代码中页给出了实现.
（注意实例代码中, 下载缓存图片代码是有bug的,可以考虑使用第三方图片库, 比如 <a href="https://github.com/onevcat/Kingfisher">Kingfisher</a>）

#### 前提: 为WebView和html建立桥

**1** 注入桥js
    - UIWebView: 拷贝 bridge_code.js 到 html中, 或在html 头部引用bridge_core.js
    - WKWebView: 什么都不需要做.

**2** 给 UIWebView/WKWebView 建立桥
```swift
let webView = WKWebView()
let bridge = ZHWebViewBridge.bridge(webView)
```

**3** 对于 WKWebView 不需要. 对于 UIWebView 需要在 webView 代理UIWebViewDelegate的回调函数webView:shouldStartLoadWithRequest:navigationType:
调用 bridge.handleRequest(request)
```swift
func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return !bridge.handleRequest(request)
    }
```

* Note:
    - WKWebView: 步骤2完全足够. 如果需要重置 webView.configuration.userContentController,
     你应该在重置后后进行步骤2, 不然桥无法正常工作
    - UIWebView: 步骤1, 2, 3都是需要的

### 原生代码与 JS 的相互交互

#### 1, 原生代码调用 js handler

**a**, 在你的html中或业务 js 中 添加 js handler
```javascript
ZHWVBridge.Core.registerJsHandler(
          "Device.updateAppVersion",
          function (version) {
            document.getElementById("native-version-container").textContent = version;
            return "js get version: " + version;
          });
```

* 说明: ZHWVBridge.Core.registerJsHandler(handlerName, callback)

**b**, 原生代码调用 js handler
```swift
bridge.callJsHandler(
            "Device.updateAppVersion",
            args: ["1.2"],
            callback: { (data:AnyObject?) in
                // here data should be "js get version: 1.2"
                ...
        })
```
* 说明: bridge.callJsHandler(handlerName, 传递给js的参数数组, callback)


#### 2, Js 调用原生 handler

**a**, 原生代码中, bridge 注册 native handler
```swift
bridge.registerHandler("Image.updatePlaceHolder") { (args:[AnyObject]) -> (Bool, [AnyObject]?) in
            return (true, ["place_holder.png"])
        }
```

**b**, js 调用原生 handler
```javascript
ZHWVBridge.Core.callNativeHandler(
            "Image.updatePlaceHolder",
            [],
            function(placeHolder) {
              var items = document.getElementsByTagName('img');
              for (var i = 0, count = items.length; i < count; ++i) {
                var item = items[i];
                if (item.src.toLocaleLowerCase() == "file:///default_cover") {
                  item.src = placeHolder;
                }
              }
            });
```

* 说明: ZHWVBridge.Core.callNativeHandler(handlerName, 传递给原生handler的参数数组, 成功回调, 失败回调)

