# WebViewBridge.Swift


[![Language: Swift 4](https://img.shields.io/badge/language-Swift%204-f48041.svg?style=flat)](https://developer.apple.com/swift)
![Platform: iOS 8+](https://img.shields.io/badge/platform-iOS%208%2B-blue.svg?style=flat)
[![Cocoapods compatible](https://img.shields.io/badge/Cocoapods-compatible-4BC51D.svg?style=flat)](https://cocoapods.org)
[![License: MIT](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat)](https://github.com/jiecao-fm/SwiftTheme/blob/master/LICENSE)


A lightweight bridge for WebView and native code written in Swift.
Bridge is not a new topic, there are existing awesome projects, <a href="https://github.com/apache/Cordova-ios">Cordova(PhoneGap)</a>, <a href="https://github.com/marcuswestin/WebViewJavascriptBridge">WebViewJavascriptBridge</a> and so on.
Honestly speaking, WebViewBridge.Swift provides you another choice, but far from satisfying. 

- Existing projects:
    - Cordova(PhoneGap) is a great project and cross platform, well tested. However if we do not want to develop hybrid app, it seems kind of too complex and hard to integrate to our app.
    - WebViewJavascriptBridge is simple and have both iOS and android version.
    - Disadvantages:
        - both of them use iframe(UIWebView), not easy to use
        - no swift version.
- WebViewBridge.Swift:
    - Use JavaScriptCore, deprecate iframe(not all, may use iframe before webViewDidFinishLoad).
    - Full Swift, and easy to use.
    - Support both UIWebView and WKWebView

If you just want to integrate bridge feature to you app, WebViewBridge.Swift supplies you another choice. It's brief, simple, optimized for ios, but works well.

If your have any question, you can email me(zhangbozhb@gmail.com) or leave message.

## Requirements

* iOS 8.0+
* Xcode 7.0 or above


###ScreenShots
![WebViewBridge.Swift](https://github.com/zhangbozhb/WebViewBridge.Swift/blob/master/screenshots_1.gif)

## Usage


#### Set up bridge between your webView and html

**1** Set up bridge for your UIWebView/WKWebView
```swift
let bridge = ZHWebViewBridge<WKWebView>.bridge(WKWebView())
let bridge = ZHWebViewBridge<UIWebView>.bridge(UIWebView())
```
* Note: if you set bridge for UIWebView
    * copy bridge.js to your html file
    * manually call bridge.teardown() or release bridge, bridge will recover UIWebView.delegate


### Native JS code Interaction

#### 1, Native call js handler

**a**, write js handler in you html or you business js
```javascript
ZHBridge.Core.registerJsHandler(
          "Device.updateAppVersion",
          function (version) {
            document.getElementById("native-version-container").textContent = version;
            return "js get version: " + version;
          });
```
version before 2.2, please use ZHWebViewBridge.bridge(UIWebView())

* Note: ZHBridge.Core.registerJsHandler(handlerName, callback)

**b**, call js handler from native
```swift
bridge.callJsHandler(
            "Device.updateAppVersion",
            args: ["1.2"],
            callback: { (data:Any?) in
                // here data should be "js get version: 1.2"
                ...
        })
```
* Note: bridge.callJsHandler(handlerName, argArrayPassToJs, callback)

#### 2, Js call Native handler

**a**, write and register native handler to bridge
```swift
bridge.registerHandler("Image.updatePlaceHolder") { (args:[Any]) -> (Bool, [Any]?) in
            return (true, ["place_holder.png"])
        }
```

**b**, call from js
```javascript
ZHBridge.Core.callNativeHandler(
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

* Note: ZHBridge.Core.callNativeHandler(handlerName, argArrayPassToNativeHandler, successCallback, failCallback)


#### 3, Others
**a**, add user plugin script
```swift
bridge.addUserPluginScript("your script")   // when run your plugin: WKWebView at document start， UIWebview will try to run script webViewDidStartLoad(:) webViewDidFinishLoad(:)
```



## Installation

### CocoaPods

To integrate WebViewBridge.Swift into your Xcode project using CocoaPods, specify it in your `Podfile`:

``` ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!

pod 'WebViewBridge.Swift'
```
default support is Swift 4. If you use it in prevous version of Swift. 1.x for Swift3.



# WebViewBridge.Swift 介绍
WebViewBridge.Swift 封装了WebView js 和 Native代码的调用.
WebView与Native桥并不是一个新的话题, 在很早以前就有实现了, 也有很好的实现.
比如 <a href="https://github.com/apache/Cordova-ios">Cordova(PhoneGap)</a>, <a href="https://github.com/marcuswestin/WebViewJavascriptBridge">WebViewJavascriptBridge</a>
桥本身的技术并不困难, 实现也都大同小异, 既然已经有项目 <a href="https://github.com/apache/Cordova-ios">Cordova(PhoneGap)</a>, <a href="https://github.com/marcuswestin/WebViewJavascriptBridge">WebViewJavascriptBridge</a>, 那还有必要重复再造轮子么?
- Cordova-ios: 本身是一个很了不起的项目, 提供了多个平台, 对于 Hybrid App而言, 是一个很好的选择;
如果你编写的不是Hybrid App, 只是想简单的集成 bridge这个功能, Cordova 就显得过于复杂了, 不方面集成, 另外暂时也无 swift 版本的
- WebViewJavascriptBridge: 也很不错, 同时提供了 iOS, android 版本, 集成也简单方便. 有以下几点不足:
    - UIWebView/WKWebView: 采用的旧式的 iframe 方式来实现, 集成相对麻烦
    - 没有提供 Swift 版本

WebViewBridge.Swift 给你提供了另一种可能, 与其他相比由以下优点:
- 采用 JavaScriptCore, 弃用iframe，使用更简单 (并非完全弃用iframe, 在webViewDidFinishLoad之前可能仍会使用iframe)
- 全 Swift 实现

此外: 对于此外常见的 webview点击下载图片, 实例代码中页给出了实现.
（注意实例代码中, 下载缓存图片代码是有bug的,可以考虑使用第三方图片库, 比如 <a href="https://github.com/onevcat/Kingfisher">Kingfisher</a>）

#### 前提: 为WebView和html建立桥

**1** 给 UIWebView/WKWebView 建立桥
```swift
let bridge = ZHWebViewBridge<WKWebView>.bridge(WKWebView())
let bridge = ZHWebViewBridge<UIWebView>.bridge(UIWebView())
```
2.2之前的版本：使用 ZHWebViewBridge.bridge(UIWebView())

* Note: 对于 UIWebView 需要注意一下事情
    * 拷贝 bridge.js 代码到你的html文件中(对于 UIWebView，如果没有拷贝，默认行为，会修改 UIWebView delegate，然后 自动 webViewDidFinishLoad: 的时候加入 bridge.js)
    * 主动调用 bridge.teardown 或者 bridge 释放的时候，会自动恢复 delegate

### 原生代码与 JS 的相互交互

#### 1, 原生代码调用 js handler

**a**, 在你的html中或业务 js 中 添加 js handler
```javascript
ZHBridge.Core.registerJsHandler(
          "Device.updateAppVersion",
          function (version) {
            document.getElementById("native-version-container").textContent = version;
            return "js get version: " + version;
          });
```

* 说明: ZHBridge.Core.registerJsHandler(handlerName, callback)

**b**, 原生代码调用 js handler
```swift
bridge.callJsHandler(
            "Device.updateAppVersion",
            args: ["1.2"],
            callback: { (data:Any?) in
                // here data should be "js get version: 1.2"
                ...
        })
```
* 说明: bridge.callJsHandler(handlerName, 传递给js的参数数组, callback)


#### 2, Js 调用原生 handler

**a**, 原生代码中, bridge 注册 native handler
```swift
bridge.registerHandler("Image.updatePlaceHolder") { (args:[Any]) -> (Bool, [Any]?) in
            return (true, ["place_holder.png"])
        }
```

**b**, js 调用原生 handler
```javascript
ZHBridge.Core.callNativeHandler(
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

* 说明: ZHBridge.Core.callNativeHandler(handlerName, 传递给原生handler的参数数组, 成功回调, 失败回调)

#### 3, 其他
**a**, 添加其他的插件代码
```swift
bridge.addUserPluginScript("your script")   // 插件脚本执行时机: WKWebView document 在 main frame 开始的时候， UIWebview 会 delegate 回调 webViewDidStartLoad(:) 和 webViewDidFinishLoad(:) 均会调用
```
