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

class ZHBridgeAction {
    var actionId:Int = 0
    var name:String = ""
    var args:[Any] = []
    
    init(actionId:Int, name:String, args:[Any]) {
        self.actionId = actionId
        self.name = name
        self.args = args
    }
    
    var isValid: Bool {
        return !name.isEmpty
    }
}

class ZHBridgeActionResult {
    var actionId:Int = 0
    var status = true
    var result:Any?
    
    init(actionId:Int) {
        self.actionId = actionId
    }
    
    init(actionId:Int, status:Bool, result:Any?) {
        self.actionId = actionId
        self.status = status
        self.result = result
    }
}

open class ZHBridgeHelper {
    public final class func serializeData(_ data:Any) -> String {
        if let json = try? JSONSerialization.data(withJSONObject: data, options: JSONSerialization.WritingOptions.init(rawValue: 0)) {
            return String.init(data: json, encoding: String.Encoding.utf8)!
        }
        return ""
    }
    
    public final class func deserializeData(_ data:String) -> Any? {
        if let encodeData = data.data(using: String.Encoding.utf8), let obj = try? JSONSerialization.jsonObject(with: encodeData, options: JSONSerialization.ReadingOptions.allowFragments) {
            return obj
        }
        return nil
    }
    
    class func unpackActions(_ obj:Any?) -> [ZHBridgeAction] {
        var actions = [ZHBridgeAction]()
        if let infoString = obj as? String, let infos = self.deserializeData(infoString) as? [[String: Any]] {
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
    
    class func unpackResult(_ obj:Any?) -> Any? {
        if let infoString = obj as? String {
            return self.deserializeData(infoString)
        }
        return nil
    }
}

extension ZHBridgeActionResult {
    var validCallBack: Bool {
        return actionId != 0
    }
}


private let ZHWebViewBridgeJS = "var ZHBridge=window.ZHBridge||{};window.ZHBridge=ZHBridge;ZHBridge.Core=ZHBridge.Core||(function(){var callbackId=1;var callbacks={};var actionQueue=[];var createBridge=function(){var iFrame;iFrame=document.createElement(\"iframe\");iFrame.setAttribute(\"src\",\"ZHBridge://__BRIDGE_LOADED__\");iFrame.setAttribute(\"style\",\"display:none;\");iFrame.setAttribute(\"height\",\"0px\");iFrame.setAttribute(\"width\",\"0px\");iFrame.setAttribute(\"frameborder\",\"0\");document.body.appendChild(iFrame);setTimeout(function(){document.body.removeChild(iFrame)},0)};var callNativeHandler=function(){var actionName=arguments[0];var actionArgs=arguments[1]||[];var successCallback=arguments[2];var failCallback=arguments[3];var actionId=++callbackId;if(successCallback||failCallback){callbacks[actionId]={success:successCallback,fail:failCallback}}else{actionId=0}var action={id:actionId,name:actionName,args:actionArgs,argsCount:actionArgs.length};if(window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.ZHBridge&&window.webkit.messageHandlers.ZHBridge.postMessage){window.webkit.messageHandlers.ZHBridge.postMessage(JSON.stringify([action]))}else{if(window.zhbridge_messageHandlers&&window.zhbridge_messageHandlers.ZHBridge&&window.zhbridge_messageHandlers.ZHBridge.postMessage){window.zhbridge_messageHandlers.ZHBridge.postMessage(JSON.stringify([action]))}else{actionQueue.push(action);createBridge()}}};var getAndClearQueuedActions=function(){var json=JSON.stringify(actionQueue);actionQueue=[];return json};var callbackJs=function(){var data=arguments[0];if(!data){return}var callInfo = data;var callbackId=callInfo[\"id\"];var status=callInfo[\"status\"];var args=callInfo[\"args\"];if(!callbackId||status==undefined||args==undefined){return}var callback=callbacks[callbackId];var success=callback[\"success\"];var fail=callback[\"fail\"];if(!callback){return}var result=undefined;if(status&&success){result=success.apply(this,args)}else{if(!status&&fail){result=fail.apply(this,args)}}return result!=undefined?JSON.stringify(result):undefined};var handlerMapper={};var callJsHandler=function(data){var callInfo= data;var name=callInfo[\"name\"];var args=callInfo[\"args\"];var argsCount=callInfo[\"argsCount\"];if(!name||argsCount==undefined||argsCount!=args.length){return}var handler=handlerMapper[name];if(handler){var result=handler.apply(this,args);return result!=undefined?JSON.stringify(result):undefined}};var registerJsHandler=function(handlerName,callback){handlerMapper[handlerName]=callback};var ready=function(){var readyFunction=arguments[0];if(readyFunction){document.addEventListener(\"DOMContentLoaded\",readyFunction)}};return{getAndClearJsActions:getAndClearQueuedActions,callJsHandler:callJsHandler,callbackJs:callbackJs,registerJsHandler:registerJsHandler,callNativeHandler:callNativeHandler,ready:ready}}());"

protocol ZHWebViewBridgeProtocol:class {
    func zh_evaluateJavaScript(_ javaScriptString: String,
                               completionHandler: ((Any?,Error?) -> Void)?)
}

extension ZHWebViewBridgeProtocol {
    func zh_unpackActions(_ handler:@escaping (([ZHBridgeAction]) -> Void)) {
        zh_evaluateJavaScript("ZHBridge.Core.getAndClearJsActions()") { (res:Any?, _:Error?) in
            handler(ZHBridgeHelper.unpackActions(res))
        }
    }
    
    func zh_callHander(_ handlerName:String, args:[Any], callback:((Any?) -> Void)? = nil) {
        let handlerInfo:[String : Any] = [
            "name": handlerName,
            "args": args,
            "argsCount": args.count
        ]
        let data = ZHBridgeHelper.serializeData(handlerInfo)
        zh_evaluateJavaScript("ZHBridge.Core.callJsHandler(\(data))") { (res:Any?, _:Error?) in
            callback?(ZHBridgeHelper.unpackResult(res))
        }
    }
    
    func zh_callback(_ result:ZHBridgeActionResult) {
        if !result.validCallBack {
            return
        }

        let callbackInfo:[String:Any] = [
            "id": result.actionId,
            "status": result.status,
            "args": (result.result == nil) ? [] : [result.result!]
        ]
        let data = ZHBridgeHelper.serializeData(callbackInfo)
        zh_evaluateJavaScript("ZHBridge.Core.callbackJs(\(data))", completionHandler: nil)
    }
}

extension UIWebView: ZHWebViewBridgeProtocol {
    func zh_evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        let res = stringByEvaluatingJavaScript(from: javaScriptString)
        completionHandler?(res, nil)
    }
}

extension WKWebView: ZHWebViewBridgeProtocol {
    func zh_evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
        evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
}

class ZHBridgeWKScriptMessageHandler:NSObject, WKScriptMessageHandler {
    fileprivate(set) weak var bridge:ZHWebViewBridge!
    
    init(bridge:ZHWebViewBridge) {
        super.init()
        self.bridge = bridge
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let bridge = bridge else {
            return
        }
        
        if let body = message.body as? String , message.name == ZHBridgeName && !body.isEmpty{
            bridge.handlerActions(ZHBridgeHelper.unpackActions(body))
        }
    }
}

// MARK: extention UIWewView the ability like WKWebView
class ZHScriptMessage {
    fileprivate(set) var name:String = ""
    fileprivate(set) var body:Any?
    
    init(name:String, body:Any?) {
        self.name = name
        self.body = body
    }
}

protocol ZHScriptMessageHandler:class {
    func handle(_ message:ZHScriptMessage)
}

class ZHBridgeWBScriptMessageHandler:ZHScriptMessageHandler {
    fileprivate(set) weak var bridge:ZHWebViewBridge!
    
    init(bridge:ZHWebViewBridge) {
        self.bridge = bridge
    }
    
    
    func handle(_ message: ZHScriptMessage) {
        guard let bridge = bridge else {
            return
        }
        
        if let body = message.body as? String , message.name == ZHBridgeName && !body.isEmpty{
            DispatchQueue.main.async(execute: {
                bridge.handlerActions(ZHBridgeHelper.unpackActions(body))
            })
        }
    }
}

@objc protocol ZHBridgeScriptMessageHandlerWrapperJSExport: JSExport {
    func postMessage(_ body:Any?)
}
class ZHBridgeScriptMessageHandlerWrapper:NSObject, ZHBridgeScriptMessageHandlerWrapperJSExport {
    fileprivate(set) var name:String = ""
    fileprivate(set) var handler:ZHScriptMessageHandler
    
    init(name:String, handler:ZHScriptMessageHandler) {
        self.name = name
        self.handler = handler
    }
    
    func postMessage(_ body:Any?) {
        handler.handle(ZHScriptMessage.init(name: name, body: body))
    }
}

class ZHWebViewDelegateProxy: NSObject, UIWebViewDelegate {
    fileprivate weak var original:UIWebViewDelegate?
    fileprivate weak var proxy:UIWebViewDelegate?

    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let load = proxy?.webView?(webView, shouldStartLoadWith: request, navigationType: navigationType), !load {
            return false
        }
        return original?.webView?(webView, shouldStartLoadWith: request, navigationType: navigationType) ?? true
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        proxy?.webViewDidStartLoad?(webView)
        original?.webViewDidStartLoad?(webView)
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        proxy?.webViewDidFinishLoad?(webView)
        original?.webViewDidFinishLoad?(webView)
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        proxy?.webView?(webView, didFailLoadWithError: error)
        original?.webView?(webView, didFailLoadWithError: error)
    }
}

class ZHWebViewContentController:NSObject {
    fileprivate(set) var webView:UIWebView!
    fileprivate(set) var shouldProxyDelegate = false
    fileprivate(set) var handleRequestBlock:((UIWebView, URLRequest) -> Bool)?
    fileprivate(set) weak var jsContext:JSContext?
    fileprivate var delegateProxy:ZHWebViewDelegateProxy! = ZHWebViewDelegateProxy()
    fileprivate(set) var messageHandlers:[String:Any] = [:]
    fileprivate(set) var pluginScripts = [String]()
    fileprivate var contextKVO:Int = 0
    fileprivate let jsContextPath = "documentView.webView.mainFrame.javaScriptContext"
    fileprivate let delegatePath = "delegate"
    
    
    init(webView:UIWebView, proxyDelegate:Bool = true) {
        super.init()
        
        shouldProxyDelegate = proxyDelegate
        
        let jsContextPath = self.jsContextPath
        self.webView = webView
        jsContext = webView.value(forKeyPath: jsContextPath) as? JSContext
        webView.addObserver(self, forKeyPath: jsContextPath, options: [.initial, .new], context: &contextKVO)
        
        delegateProxy.proxy = self
        updateWebViewDelegate(webView.delegate)
        webView.addObserver(self, forKeyPath: delegatePath, options: [.initial, .new], context: &contextKVO)
    }
    
    deinit {
        webView?.removeObserver(self, forKeyPath: jsContextPath)
        webView?.removeObserver(self, forKeyPath: delegatePath)
        delegateProxy = nil
        webView = nil
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == &contextKVO else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == jsContextPath {
            if let context = change?[NSKeyValueChangeKey.newKey] as? JSContext , jsContext !== context {
                updateJsContext(context)
            }
        } else if keyPath == delegatePath {
            updateWebViewDelegate(change?[NSKeyValueChangeKey.newKey] as? UIWebViewDelegate)
        }
    }
    
    fileprivate func updateWebViewDelegate(_ delegate:UIWebViewDelegate?) {
        if delegateProxy !== delegate {
            delegateProxy.original = delegate
        }
    
        guard shouldProxyDelegate else {
            return
        }
        if delegate !== delegateProxy {
            webView.delegate = delegateProxy
        }
    }
    
    fileprivate func updateJsContext(_ context:JSContext) {
        jsContext = context
        setupUserPlugins()
        updateMessgeHandler()
    }
    
    fileprivate func updateMessgeHandler() {
        jsContext?.setObject(messageHandlers, forKeyedSubscript: NSString.init(string: "zhbridge_messageHandlers"))
    }
    
    func addScriptMessageHandler(_ scriptMessageHandler: ZHScriptMessageHandler, name: String) {
        messageHandlers[name] = ZHBridgeScriptMessageHandlerWrapper.init(name: name, handler: scriptMessageHandler)
        updateMessgeHandler()
    }
    
    fileprivate func setupUserPlugins() {
        for script in pluginScripts {
            _ = jsContext?.evaluateScript(script)
        }
    }
    
    func addUserPlugin(_ script:String) {
        if !Set(pluginScripts).contains(script) {
            pluginScripts.append(script)
            _ = jsContext?.evaluateScript(script)
        }
    }
    
    func removeUserPlugin(_ script:String) {
        let scripts = pluginScripts.flatMap { (s:String) -> String? in
            return s != script ? s : nil
        }
        if scripts.count != pluginScripts.count {
            pluginScripts = scripts
        }
    }
    
    func clearUserPlugin() {
        pluginScripts = []
    }
}

extension ZHWebViewContentController: UIWebViewDelegate {
    // update js contenxt
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if let context = webView.value(forKeyPath: jsContextPath) as? JSContext, jsContext !== context {
            updateJsContext(context)
        }
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let handled = handleRequestBlock?(webView, request) {
            return !handled
        }
        return true
    }
}

open class ZHWebViewBridge {
    fileprivate var handlerMapper:[String: (([Any]) -> (Bool, [Any]?))] = [:]

    fileprivate(set) weak var bridge:ZHWebViewBridgeProtocol?

    fileprivate var contentController:ZHWebViewContentController?   // UIWeview only

    fileprivate init(){}

    deinit {
        teardown()
    }
    
    /// initial delegate of UIWebView
    open var delegate:UIWebViewDelegate? {
        return contentController?.delegateProxy.original
    }
    
    /**
     tear down your bridge, if you call this method, your bridge will not work any more.
     Note: If you bridge for UIWebView, you should call this method, to release reference of UIWebView
     */
    open func teardown() {
        handlerMapper = [:]
        contentController = nil
        bridge = nil
    }
    
    /**
     register a handler to handle js call
     
     - parameter handlerName: handler name, unique to identify native handler
     - parameter callback:    native call back to handler js call. Input args array, return tuple. tuple.0 indicate handle status, tuple.1 args array to pass to js callback
     */
    open func registerHandler(_ handlerName:String, callback:@escaping (([Any]) -> (Bool, [Any]?))) {
        handlerMapper[handlerName] = callback
    }
    /**
     call js handler register in js
     
     - parameter handlerName: handler name, unique to identify js handler
     - parameter args:        args that will be pass to registered js handler
     - parameter callback:    callback method after js handler
     */
    open func callJsHandler(_ handlerName:String, args:[Any], callback:((Any?) -> Void)? = nil) {
        bridge?.zh_callHander(handlerName, args: args, callback: callback)
    }
    
    /**
     adds a user script.
     Note:  If bridge for UIWebView, you shoul avoid to use this method, in case it will not work as you aspect
     
     - parameter source: The user plugin script to add.
     
     - returns: whether plugin added success
     */
    open func addUserPluginScript(_ source:String) -> Bool {
        if let _ = bridge as? UIWebView {
            contentController?.addUserPlugin(source)
        } else if let webview = bridge as? WKWebView {
            webview.configuration.userContentController.addUserScript(WKUserScript.init(source: source, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        return true
    }
    
    // MARK: for UIWebView
    /**
     set up bridge for webview
     Note:  1, your should copy bridge js to your html file
            2, bridge will hold strong reference of UIWebView, you should call unbridge manually
            3, bridge will replace webView.delegate, if you want to access the origin delegate, use bridge.delegate instead
     
     - parameter webView:        webview you want to setup
     - parameter proxyDelegate: if set to false, your should manual call bridge.handleRequest(:) in method webView:shouldStartLoadWithRequest:navigationType: of UIWebViewDelegate
     
     - returns: bridge
     */
    open class func bridge(_ webView:UIWebView, proxyDelegate:Bool = true) -> ZHWebViewBridge {
        let bridge = ZHWebViewBridge()
        bridge.bridge = webView
        
        let messageHandler = ZHBridgeWBScriptMessageHandler.init(bridge: bridge)
        let contentController = ZHWebViewContentController.init(webView: webView, proxyDelegate: proxyDelegate)
        contentController.addUserPlugin(ZHWebViewBridgeJS)
        contentController.addScriptMessageHandler(messageHandler, name: ZHBridgeName)
        contentController.handleRequestBlock = { (wb:UIWebView, request:URLRequest) -> Bool in
            return bridge.handleRequest(request)
        }
        bridge.contentController = contentController
        
        return bridge
    }
    
    /**
     check whether request can handle bridge
     
     - parameter request: request
     
     - returns: true can handle, false can not handle
     */
    fileprivate final func canHandle(_ request: URLRequest) -> Bool {
        if let scheme = request.url?.scheme , scheme.caseInsensitiveCompare(ZHBridgeName) == .orderedSame {
            return true
        }
        return false
    }
    /**
     handle a request. this method should be used in webView:shouldStartLoadWithRequest:navigationType: of UIWebViewDelegate
     Note: this method has be deprecated
     
     - parameter request: request
     
     - returns: true request has handled by bridge
     */
    open func handleRequest(_ request: URLRequest) -> Bool {
        if canHandle(request) {
            bridge?.zh_unpackActions({ [weak self](actions:[ZHBridgeAction]) in
                guard let sself = self , !actions.isEmpty else {
                    return
                }
                
                for action in actions {
                    let result = ZHBridgeActionResult.init(actionId: action.actionId)
                    if let handler = sself.handlerMapper[action.name] {
                        let (status, res) = handler(action.args)
                        result.status = status
                        result.result = res
                    }
                    sself.bridge?.zh_callback(result)
                }
                })
            return true
        }
        return false
    }
    
    // MARK: for WKWebView
    /**
     set up bridge for webview
     
     - parameter webView:        webview you want to setup
     - parameter injectBridgeJs: if set to false, your should manual copy bridge js to you html, or refer bridge js in you html header
     
     - returns: bridge
     */
    open class func bridge(_ webView:WKWebView, injectBridgeJs:Bool = true) -> ZHWebViewBridge {
        let bridge = ZHWebViewBridge()
        bridge.bridge = webView
        
        if injectBridgeJs {
            webView.configuration.userContentController.addUserScript(WKUserScript.init(source: ZHWebViewBridgeJS, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        }
        let messageHandler = ZHBridgeWKScriptMessageHandler.init(bridge: bridge)
        webView.configuration.userContentController.add(messageHandler, name: ZHBridgeName)
        
        return bridge
    }
    
    fileprivate func handlerActions(_ actions:[ZHBridgeAction]) {
        for action in actions {
            let result = ZHBridgeActionResult.init(actionId: action.actionId)
            if let handler = handlerMapper[action.name] {
                let (status, res) = handler(action.args)
                result.status = status
                result.result = res
            }
            bridge?.zh_callback(result)
        }
    }
}
