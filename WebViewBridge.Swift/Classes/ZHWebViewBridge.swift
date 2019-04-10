//
//  ZHWebViewBridge.swift
//  WebViewBridge.Swift
//
//  Created by travel on 16/6/19.
//
//	OS X 10.10+ and iOS 8.0+
//	Only use with ARC
//
//	The MIT License (MIT)
//	Copyright © 2016 travel.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy of
//	this software and associated documentation files (the "Software"), to deal in
//	the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//	the Software, and to permit persons to whom the Software is furnished to do so,
//	subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit
import WebKit
import JavaScriptCore

private let ZHBridgeName = "ZHBridge"

/// native representation of js action
struct ZHBridgeAction {
    /// action id: identifier js action
    let actionId: Int

    /// action name: the action that js want to call
    let name: String
    /// args js pass to action

    let args: [Any]

    init(actionId: Int, name: String, args: [Any] = []) {
        self.actionId = actionId
        self.name = name
        self.args = args
    }

    /// check action is valid: true valid, false invalid
    var isValid: Bool {
        return !name.isEmpty
    }
}

/// navtive result for js call
struct ZHBridgeActionResult {
    /// js call identifire: js use this for callback
    let actionId: Int

    /// native execute status: true success, false failed
    let status: Bool

    /// native execute result
    let result: Any?

    init(actionId: Int, status: Bool, result: Any?) {
        self.actionId = actionId
        self.status = status
        self.result = result
    }

    /// true if is valid callback for js, false invalid
    var isValidCallBack: Bool {
        return actionId != 0
    }
}

/// bridge helper:  serilize, deserialize data
open class ZHBridgeHelper {

    /// json string serialize data
    ///
    /// - Parameter data: data
    /// - Returns: json string type of data
    public final class func serializeData(_ data: Any) -> String {
        if let json = try? JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.init(rawValue: 0)) {
            return String.init(data: json, encoding: String.Encoding.utf8)!
        }
        return ""
    }

    /// deserialize json string data
    ///
    /// - Parameter data: json string data
    /// - Returns: data parsed
    public final class func deserializeData(_ data: String) -> Any? {
        if let encodeData = data.data(using: String.Encoding.utf8), let obj = try? JSONSerialization.jsonObject(with: encodeData, options: JSONSerialization.ReadingOptions.allowFragments) {
            return obj
        }
        return nil
    }

    /// unpack action
    ///
    /// - Parameter data: data from js
    /// - Returns: actions
    class func unpackActions(_ data: Any?) -> [ZHBridgeAction] {
        var actions = [ZHBridgeAction]()
        if let infoString = data as? String, let infos = self.deserializeData(infoString) as? [[String: Any]] {
            for info in infos {
                if let actionId = info["id"] as? NSNumber, let name = info["name"] as? String, let args = info["args"] as? [Any] {
                    let action = ZHBridgeAction.init(actionId: actionId.intValue, name: name, args: args)
                    if action.isValid {
                        actions.append(action)
                    }
                }
            }
        }
        return actions
    }

    /// upack result from js
    ///
    /// - Parameter data: data from js
    /// - Returns: result
    class func unpackResult(_ data: Any?) -> Any? {
        if let infoString = data as? String {
            return self.deserializeData(infoString)
        }
        return nil
    }
}

private let ZHWebViewBridgeJS = "var ZHBridge=window.ZHBridge||{};window.ZHBridge=ZHBridge;ZHBridge.Core=ZHBridge.Core||(function(){var callbackId=1;var callbacks={};var actionQueue=[];var createBridge=function(){var iFrame;iFrame=document.createElement(\"iframe\");iFrame.setAttribute(\"src\",\"ZHBridge://__BRIDGE_LOADED__\");iFrame.setAttribute(\"style\",\"display:none;\");iFrame.setAttribute(\"height\",\"0px\");iFrame.setAttribute(\"width\",\"0px\");iFrame.setAttribute(\"frameborder\",\"0\");document.body.appendChild(iFrame);setTimeout(function(){document.body.removeChild(iFrame)},0)};var callNativeHandler=function(){var actionName=arguments[0];var actionArgs=arguments[1]||[];var successCallback=arguments[2];var failCallback=arguments[3];var actionId=++callbackId;if(successCallback||failCallback){callbacks[actionId]={success:successCallback,fail:failCallback}}else{actionId=0}var action={id:actionId,name:actionName,args:actionArgs,argsCount:actionArgs.length};if(window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.ZHBridge&&window.webkit.messageHandlers.ZHBridge.postMessage){window.webkit.messageHandlers.ZHBridge.postMessage(JSON.stringify([action]))}else{if(window.zhbridge_messageHandlers&&window.zhbridge_messageHandlers.ZHBridge&&window.zhbridge_messageHandlers.ZHBridge.postMessage){window.zhbridge_messageHandlers.ZHBridge.postMessage(JSON.stringify([action]))}else{actionQueue.push(action);createBridge()}}};var getAndClearQueuedActions=function(){var json=JSON.stringify(actionQueue);actionQueue=[];return json};var callbackJs=function(){var data=arguments[0];if(!data){return}var callInfo = data;var callbackId=callInfo[\"id\"];var status=callInfo[\"status\"];var args=callInfo[\"args\"];if(!callbackId||status==undefined||args==undefined){return}var callback=callbacks[callbackId];var success=callback[\"success\"];var fail=callback[\"fail\"];if(!callback){return}var result=undefined;if(status&&success){result=success.apply(this,args)}else{if(!status&&fail){result=fail.apply(this,args)}}return result!=undefined?JSON.stringify(result):undefined};var handlerMapper={};var callJsHandler=function(data){var callInfo= data;var name=callInfo[\"name\"];var args=callInfo[\"args\"];var argsCount=callInfo[\"argsCount\"];if(!name||argsCount==undefined||argsCount!=args.length){return}var handler=handlerMapper[name];if(handler){var result=handler.apply(this,args);return result!=undefined?JSON.stringify(result):undefined}};var registerJsHandler=function(handlerName,callback){handlerMapper[handlerName]=callback};var ready=function(){var readyFunction=arguments[0];if(readyFunction){document.addEventListener(\"DOMContentLoaded\",readyFunction)}};return{getAndClearJsActions:getAndClearQueuedActions,callJsHandler:callJsHandler,callbackJs:callbackJs,registerJsHandler:registerJsHandler,callNativeHandler:callNativeHandler,ready:ready}}());"

protocol ZHWebViewBridgeProtocol: class {

    /// evaluate js
    ///
    /// - Parameters:
    ///   - javaScriptString: js string
    ///   - completionHandler: complete handler
    func zh_evaluateJavaScript(_ javaScriptString: String,
                               completionHandler: ((Any?, Error?) -> Void)?)
}

extension DispatchQueue {

    /// run block on ui queue
    ///
    /// - Parameter block: block
    func zh_safeAsync(_ block: @escaping ()->Void) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            async { block() }
        }
    }
}

extension ZHWebViewBridgeProtocol {
    /// call js handler
    ///
    /// - Parameters:
    ///   - handlerName: name of the js handler to call
    ///   - args: args pass to js handler
    ///   - callback: process the js handler result
    func zh_callJsHandlerFromNative(_ handlerName: String, args: [Any], callback: ((Any?) -> Void)? = nil) {
        let handlerInfo: [String: Any] = [
            "name": handlerName,
            "args": args,
            "argsCount": args.count
        ]
        let data = ZHBridgeHelper.serializeData(handlerInfo)
        zh_evaluateJavaScript("ZHBridge.Core.callJsHandler(\(data))") { (res: Any?, _:Error?) in
            callback?(ZHBridgeHelper.unpackResult(res))
        }
    }

    /// call back with action result
    /// execute js callback with action result
    ///
    /// - Parameter result: result of js action
    func zh_callback(forResult result: ZHBridgeActionResult) {
        if !result.isValidCallBack {
            return
        }

        let callbackInfo: [String: Any] = [
            "id": result.actionId,
            "status": result.status,
            "args": (result.result == nil) ? [] : [result.result!]
        ]
        let data = ZHBridgeHelper.serializeData(callbackInfo)
        zh_evaluateJavaScript("ZHBridge.Core.callbackJs(\(data))", completionHandler: nil)
    }

    /// unpack actions
    /// UIWebView only:
    ///
    /// - Parameter handler: process to actions
    func zh_unpackActions(_ handler:@escaping (([ZHBridgeAction]) -> Void)) {
        zh_evaluateJavaScript("ZHBridge.Core.getAndClearJsActions()") { (res: Any?, _:Error?) in
            handler(ZHBridgeHelper.unpackActions(res))
        }
    }
}

// MARK: - bridge extension for UIWebView
extension ZHWebViewBridgeProtocol where Self: UIWebView {
    func zh_evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        DispatchQueue.main.zh_safeAsync {
            let res = self.stringByEvaluatingJavaScript(from: javaScriptString)
            completionHandler?(res, nil)
        }
    }

    /// unpack actions
    ///
    /// - Parameter handler: process to actions
    func zh_unpackActions(_ handler:@escaping (([ZHBridgeAction]) -> Void)) {
        zh_evaluateJavaScript("ZHBridge.Core.getAndClearJsActions()") { (res: Any?, _:Error?) in
            handler(ZHBridgeHelper.unpackActions(res))
        }
    }
}

// MARK: - bridge extension for WKWebView
extension ZHWebViewBridgeProtocol where Self: WKWebView {
    func zh_evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        DispatchQueue.main.zh_safeAsync {
            self.evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
        }
    }
}

/// bridge action handler
protocol ZHBridgeActionHandlerProtocol: class {
    func handleActions(_ actions: [ZHBridgeAction])
}

/// message handler for wkwebview
class ZHBridgeWKScriptMessageHandler: NSObject, WKScriptMessageHandler {
    fileprivate(set) weak var handler: ZHBridgeActionHandlerProtocol?

    init(handler: ZHBridgeActionHandlerProtocol) {
        super.init()
        self.handler = handler
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let handler = handler else {
            return
        }

        if let body = message.body as? String, message.name == ZHBridgeName && !body.isEmpty {
            handler.handleActions(ZHBridgeHelper.unpackActions(body))
        }
    }
}

// MARK: extention UIWewView the ability like WKWebView
class ZHScriptMessage {
    fileprivate(set) var name: String = ""
    fileprivate(set) var body: Any?

    init(name: String, body: Any?) {
        self.name = name
        self.body = body
    }
}

protocol ZHScriptMessageHandler: class {
    func handle(_ message: ZHScriptMessage)
}

class ZHBridgeWBScriptMessageHandler: NSObject, ZHScriptMessageHandler {
    fileprivate(set) weak var handler: ZHBridgeActionHandlerProtocol?

    init(handler: ZHBridgeActionHandlerProtocol) {
        self.handler = handler
        super.init()
    }

    func handle(_ message: ZHScriptMessage) {
        guard let handler = handler else {
            return
        }

        if let body = message.body as? String, message.name == ZHBridgeName && !body.isEmpty {
            DispatchQueue.main.zh_safeAsync {
                handler.handleActions(ZHBridgeHelper.unpackActions(body))
            }
        }
    }
}

@objc protocol ZHBridgeScriptMessageHandlerWrapperJSExport: JSExport {
    func postMessage(_ body: Any?)
}
class ZHBridgeScriptMessageHandlerWrapper: NSObject, ZHBridgeScriptMessageHandlerWrapperJSExport {
    fileprivate(set) var name: String = ""
    fileprivate(set) var handler: ZHScriptMessageHandler

    init(name: String, handler: ZHScriptMessageHandler) {
        self.name = name
        self.handler = handler
        super.init()
    }

    func postMessage(_ body: Any?) {
        handler.handle(ZHScriptMessage.init(name: name, body: body))
    }
}

class ZHWebViewDelegateProxy: NSObject, UIWebViewDelegate {
    weak var original: UIWebViewDelegate?
    weak var controller: ZHWebViewContentController?

    override init() {
        super.init()
    }

    // 消息转发
    override func forwardingTarget(for aSelector: Selector!) -> Any? {
        return original
    }

    override func responds(to aSelector: Selector!) -> Bool {
        return super.responds(to: aSelector) || (original?.responds(to: aSelector) ?? false)
    }

    // 代理实现
    func webViewDidFinishLoad(_ webView: UIWebView) {
        controller?.updateJsContextIfNeeded()
        original?.webViewDidFinishLoad?(webView)
    }

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebView.NavigationType) -> Bool {
        if let handled = controller?.requestHandler?.handleRequest(request) {
            return !handled
        }
        return original?.webView?(webView, shouldStartLoadWith: request, navigationType: navigationType) ?? true
    }
}

/// request handler
protocol ZHRequestHandler: class {
    func handleRequest(_ request: URLRequest) -> Bool
}

class ZHWebViewContentController: NSObject {
    fileprivate(set) weak var webView: UIWebView?
    fileprivate let shouldProxyDelegate: Bool

    fileprivate let delegateProxy: ZHWebViewDelegateProxy = ZHWebViewDelegateProxy()
    fileprivate(set) weak var jsContext: JSContext?
    fileprivate var delegateObservation: NSKeyValueObservation?

    fileprivate(set) weak var requestHandler: ZHRequestHandler?

    fileprivate(set) var messageHandler = InnerMessageHandler.init()
    fileprivate(set) var pluginScripts = [String]()
    fileprivate let jsContextPath = "documentView.webView.mainFrame.javaScriptContext"
    fileprivate let jsMessageHandlersKey = "zhbridge_messageHandlers"

    class InnerMessageHandler: NSObject {
        var messageHandlers: [String: ZHBridgeScriptMessageHandlerWrapper] = [:]

        override init() {
            super.init()
        }

        func addScriptMessageHandler(_ scriptMessageHandler: ZHScriptMessageHandler, name: String) {
            messageHandlers[name] = ZHBridgeScriptMessageHandlerWrapper.init(name: name, handler: scriptMessageHandler)
        }
    }

    init(webView: UIWebView, proxyDelegate: Bool = true) {
        self.webView = webView
        shouldProxyDelegate = proxyDelegate
        super.init()
        self.delegateProxy.controller = self
        delegateProxy.original = webView.delegate

        if shouldProxyDelegate {
            webView.delegate = delegateProxy
            delegateObservation = webView.observe(\UIWebView.delegate, options: [.initial, .new]) { [weak self](_, values) in
                guard let sself = self, let nv = values.newValue else {
                    return
                }
                if let delegate = nv, delegate === sself.delegateProxy {
                    return
                }
                sself.webView?.delegate = sself.delegateProxy
                sself.delegateProxy.original = nv
            }
        }
        updateJsContextIfNeeded()
    }

    deinit {
        delegateObservation = nil
        webView?.delegate = delegateProxy.original
    }

    fileprivate func updateJsContext(_ context: JSContext) {
        jsContext = context
        setupUserPlugins()
        updateMessgeHandler()
    }

    fileprivate func updateMessgeHandler() {
        jsContext?.setObject(messageHandler, forKeyedSubscript: jsMessageHandlersKey as NSString)
    }

    func addScriptMessageHandler(_ scriptMessageHandler: ZHScriptMessageHandler, name: String) {
        messageHandler.addScriptMessageHandler(scriptMessageHandler, name: name)
        updateMessgeHandler()
    }

    fileprivate func setupUserPlugins() {
        for script in pluginScripts {
            _ = jsContext?.evaluateScript(script)
        }
    }

    func addUserPlugin(_ script: String) {
        if !Set(pluginScripts).contains(script) {
            pluginScripts.append(script)
            _ = jsContext?.evaluateScript(script)
        }
    }

    func removeUserPlugin(_ script: String) {
        let scripts = pluginScripts.compactMap { (s: String) -> String? in
            return s != script ? s : nil
        }
        if scripts.count != pluginScripts.count {
            pluginScripts = scripts
        }
    }

    func clearUserPlugin() {
        pluginScripts = []
    }

    /// update js contentx if needed
    func updateJsContextIfNeeded() {
        guard let context = webView?.value(forKeyPath: jsContextPath) as? JSContext else {
            return
        }

        if jsContext !== context || context.objectForKeyedSubscript(jsMessageHandlersKey) == nil {
            updateJsContext(context)
        }
    }
}

/// native call back to handler js call. Input args array, return tuple. tuple.0 indicate handle status, tuple.1 args array to pass to js callback
public typealias ZHBridgeActionCallback = (([Any]) -> (Bool, [Any]?))
class ZHBridgeActionHandlerImpl {
    var handlerMapper: [String: ZHBridgeActionCallback] = [:]
    weak var bridge: ZHWebViewBridgeProtocol?

    deinit {
        handlerMapper = [:]
    }

    /**
     register a handler to handle js call
     
     - parameter handlerName: handler name, unique to identify native handler
     - parameter callback:    native call back to handler js call. Input args array, return tuple. tuple.0 indicate handle status, tuple.1 args array to pass to js callback
     */
    func registerHandler(_ handlerName: String, callback:@escaping ZHBridgeActionCallback) {
        handlerMapper[handlerName] = callback
    }
}

extension ZHBridgeActionHandlerImpl: ZHBridgeActionHandlerProtocol {
    func handleActions(_ actions: [ZHBridgeAction]) {
        for action in actions {
            if let handler = handlerMapper[action.name] {
                let (status, res) = handler(action.args)
                bridge?.zh_callback(forResult: ZHBridgeActionResult.init(actionId: action.actionId, status: status, result: res))
            } else {
                bridge?.zh_callback(forResult: ZHBridgeActionResult.init(actionId: action.actionId, status: false, result: nil))
            }
        }
    }
}

extension ZHBridgeActionHandlerImpl: ZHRequestHandler {
    /**
     handle a request. this method should be used in webView:shouldStartLoadWithRequest:navigationType: of UIWebViewDelegate
     Note: this method has be deprecated
     
     - parameter request: request
     
     - returns: true request has handled by bridge
     */
    open func handleRequest(_ request: URLRequest) -> Bool {
        // check input request is bridge request
        func isBridgeRequest() -> Bool {
            if let scheme = request.url?.scheme, scheme.caseInsensitiveCompare(ZHBridgeName) == .orderedSame {
                return true
            }
            return false
        }
        if isBridgeRequest() {
            bridge?.zh_unpackActions({ [weak self](actions: [ZHBridgeAction]) in
                self?.handleActions(actions)
            })
            return true
        }
        return false
    }
}

open class ZHWebViewBridge<WebView: AnyObject> {
    let actionHander: ZHBridgeActionHandlerImpl

    fileprivate(set) weak var bridge: WebView?

    fileprivate var contentController: ZHWebViewContentController?   // UIWeview only

    fileprivate init() {
        actionHander = ZHBridgeActionHandlerImpl.init()
    }

    deinit {
        teardown()
    }

    /**
     tear down your bridge, if you call this method, your bridge will not work any more.
     
     Note:
     for UIWebView: recover webview delegate
     for WKWebView: will remove script handler added by self
     */
    open func teardown() {
        // WKWebView
        // remove script message handler
        if let bg = bridge as? WKWebView {
            bg.configuration.userContentController.removeScriptMessageHandler(forName: ZHBridgeName)
        }

        // UIWebView
        // recover delegate
        if let bg = bridge as? UIWebView, let delegate = contentController?.delegateProxy.original {
            bg.delegate = delegate
        }
        contentController = nil

        bridge = nil
    }

    /**
     register a handler to handle js call
     
     - parameter handlerName: handler name, unique to identify native handler
     - parameter callback:    native call back to handler js call. Input args array, return tuple. tuple.0 indicate handle status, tuple.1 args array to pass to js callback
     */
    open func registerHandler(_ handlerName: String, callback:@escaping ZHBridgeActionCallback) {
        actionHander.registerHandler(handlerName, callback: callback)
    }
}

// MARK: - webview support bridge
extension UIWebView: ZHWebViewBridgeProtocol {

}
// MARK: - wkweb view support bridge
extension WKWebView: ZHWebViewBridgeProtocol {
}

// MARK: - bridge for WKWebView
extension ZHWebViewBridge where WebView: WKWebView {
    /**
     call js handler register in js
     
     - parameter handlerName: handler name, unique to identify js handler
     - parameter args:        args that will be pass to registered js handler
     - parameter callback:    callback method after js handler
     */
    public func callJsHandler(_ handlerName: String, args: [Any], callback: ((Any?) -> Void)? = nil) {
        bridge?.zh_callJsHandlerFromNative(handlerName, args: args, callback: callback)
    }

    /// adds a user script.
    ///
    /// scripts added to main frame and run at document start
    ///
    /// - Parameter source: The user plugin script to add.
    /// - Returns: whether plugin added success
    open func addUserPluginScript(_ source: String) -> Bool {
        bridge?.configuration.userContentController.addUserScript(WKUserScript.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        return true
    }

    /// set up bridge for webview
    ///
    /// Note: 1, WKWebView, bridge is one-to-one, muilti bridge for one webview is not allowed and promise to crash.
    /// 2, bridge release or manual call teardown will will remove script handler added by bridge
    ///
    /// - Parameters:
    ///   - webView: webview you want to setup
    ///   - injectBridgeJs: if set to false, your should manual copy bridge js to you html, or refer bridge js in you html header
    /// - Returns: bridge
    open class func bridge(_ webView: WebView, injectBridgeJs: Bool = true) -> ZHWebViewBridge<WebView> {
        let bridge = ZHWebViewBridge<WebView>()
        bridge.bridge = webView
        bridge.actionHander.bridge = webView

        if injectBridgeJs {
            webView.configuration.userContentController.addUserScript(WKUserScript.init(source: ZHWebViewBridgeJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        webView.configuration.userContentController.add(ZHBridgeWKScriptMessageHandler.init(handler: bridge.actionHander), name: ZHBridgeName)

        return bridge
    }
}

// MARK: - bridge for UIWebView
extension ZHWebViewBridge where WebView: UIWebView {
    /// initial delegate of UIWebView
    open var delegate: UIWebViewDelegate? {
        return contentController?.delegateProxy.original
    }

    /**
     call js handler register in js
     
     - parameter handlerName: handler name, unique to identify js handler
     - parameter args:        args that will be pass to registered js handler
     - parameter callback:    callback method after js handler
     */
    public func callJsHandler(_ handlerName: String, args: [Any], callback: ((Any?) -> Void)? = nil) {
        bridge?.zh_callJsHandlerFromNative(handlerName, args: args, callback: callback)
    }

    /// adds a user script.
    ///
    /// scripts run at webViewDidFinishLoad(:)
    ///
    /// - Parameter source: The user plugin script to add.
    /// - Returns: whether plugin added success
    open func addUserPluginScript(_ source: String) -> Bool {
        contentController?.addUserPlugin(source)
        return true
    }

    /**
     set up bridge for webview
     Note:  1, your should copy bridge js to your html file
     2, bridge will replace webView.delegate, if you want to access the origin delegate, use bridge.delegate instead
     3, multi bridge for on webview is not allowed, or else bridge behavior is unexpected
     4, bridge release or manual call teardown will recover webview delegate
     
     - parameter webView:        webview you want to setup
     - parameter proxyDelegate: if set to false, your should manual call bridge.handleRequest(:) in method webView:shouldStartLoadWithRequest:navigationType: of UIWebViewDelegate
     
     - returns: bridge
     */
    open class func bridge(_ webView: WebView, proxyDelegate: Bool = true) -> ZHWebViewBridge<WebView> {
        let bridge = ZHWebViewBridge<WebView>()
        bridge.bridge = webView
        bridge.actionHander.bridge = webView

        let contentController = ZHWebViewContentController.init(webView: webView, proxyDelegate: proxyDelegate)
        contentController.addUserPlugin(ZHWebViewBridgeJS)
        contentController.addScriptMessageHandler(ZHBridgeWBScriptMessageHandler.init(handler: bridge.actionHander), name: ZHBridgeName)
        contentController.requestHandler = bridge.actionHander
        bridge.contentController = contentController

        return bridge
    }

    /**
     handle a request. this method should be used in webView:shouldStartLoadWithRequest:navigationType: of UIWebViewDelegate
     
     - parameter request: request
     
     - returns: true request has handled by bridge
     */
    open func handleRequest(_ request: URLRequest) -> Bool {
        return actionHander.handleRequest(request)
    }

}
