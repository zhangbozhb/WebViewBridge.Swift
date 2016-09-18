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
    var args:[AnyObject] = []
    
    init(actionId:Int, name:String, args:[AnyObject]) {
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
    var result:AnyObject?
    
    init(actionId:Int) {
        self.actionId = actionId
    }
    
    init(actionId:Int, status:Bool, result:AnyObject?) {
        self.actionId = actionId
        self.status = status
        self.result = result
    }
}

public class ZHBridgeHelper {
    public final class func serializeData(data:AnyObject) -> String {
        if let json = try? NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions.init(rawValue: 0)) {
            return NSString.init(data: json, encoding: NSUTF8StringEncoding) as! String
        }
        return ""
    }
    
    public final class func deserializeData(data:String) -> AnyObject? {
        if let encodeData = data.dataUsingEncoding(NSUTF8StringEncoding), obj = try? NSJSONSerialization.JSONObjectWithData(encodeData, options: NSJSONReadingOptions.AllowFragments) {
            return obj
        }
        return nil
    }
    
    class func unpackActions(obj:AnyObject?) -> [ZHBridgeAction] {
        var actions = [ZHBridgeAction]()
        if let infoString = obj as? String, infos = self.deserializeData(infoString) as? [[String: AnyObject]] {
            for info in infos {
                if let actionId = info["id"] as? NSNumber, name = info["name"] as? String, args = info["args"] as? [AnyObject] {
                    let action = ZHBridgeAction.init(actionId: actionId.integerValue, name: name, args: args)
                    if action.isValid {
                        actions.append(action)
                    }
                }
            }
        }
        return actions
    }
    
    class func unpackResult(obj:AnyObject?) -> AnyObject? {
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


private let ZHWebViewBridgeJS = "var ZHBridge=window.ZHBridge||{};window.ZHBridge=ZHBridge;ZHBridge.Core=ZHBridge.Core||(function(){var callbackId=1;var callbacks={};var actionQueue=[];var createBridge=function(){var iFrame;iFrame=document.createElement(\"iframe\");iFrame.setAttribute(\"src\",\"ZHBridge://__BRIDGE_LOADED__\");iFrame.setAttribute(\"style\",\"display:none;\");iFrame.setAttribute(\"height\",\"0px\");iFrame.setAttribute(\"width\",\"0px\");iFrame.setAttribute(\"frameborder\",\"0\");document.body.appendChild(iFrame);setTimeout(function(){document.body.removeChild(iFrame)},0)};var callNativeHandler=function(){var actionName=arguments[0];var actionArgs=arguments[1]||[];var successCallback=arguments[2];var failCallback=arguments[3];var actionId=++callbackId;if(successCallback||failCallback){callbacks[actionId]={success:successCallback,fail:failCallback}}else{actionId=0}var action={id:actionId,name:actionName,args:actionArgs,argsCount:actionArgs.length};if(window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.ZHBridge&&window.webkit.messageHandlers.ZHBridge.postMessage){window.webkit.messageHandlers.ZHBridge.postMessage(JSON.stringify([action]))}else{if(window.zhbridge_messageHandlers&&window.zhbridge_messageHandlers.ZHBridge&&window.zhbridge_messageHandlers.ZHBridge.postMessage){window.zhbridge_messageHandlers.ZHBridge.postMessage(JSON.stringify([action]))}else{actionQueue.push(action);createBridge()}}};var getAndClearQueuedActions=function(){var json=JSON.stringify(actionQueue);actionQueue=[];return json};var callbackJs=function(){var data=arguments[0];if(!data){return}var callInfo=JSON.parse(data);var callbackId=callInfo[\"id\"];var status=callInfo[\"status\"];var args=callInfo[\"args\"];if(!callbackId||status==undefined||args==undefined){return}var callback=callbacks[callbackId];var success=callback[\"success\"];var fail=callback[\"fail\"];if(!callback){return}var result=undefined;if(status&&success){result=success.apply(this,args)}else{if(!status&&fail){result=fail.apply(this,args)}}return result!=undefined?JSON.stringify(result):undefined};var handlerMapper={};var callJsHandler=function(data){var callInfo=JSON.parse(data);var name=callInfo[\"name\"];var args=callInfo[\"args\"];var argsCount=callInfo[\"argsCount\"];if(!name||argsCount==undefined||argsCount!=args.length){return}var handler=handlerMapper[name];if(handler){var result=handler.apply(this,args);return result!=undefined?JSON.stringify(result):undefined}};var registerJsHandler=function(handlerName,callback){handlerMapper[handlerName]=callback};var ready=function(){var readyFunction=arguments[0];if(readyFunction){document.addEventListener(\"DOMContentLoaded\",readyFunction)}};return{getAndClearJsActions:getAndClearQueuedActions,callJsHandler:callJsHandler,callbackJs:callbackJs,registerJsHandler:registerJsHandler,callNativeHandler:callNativeHandler,ready:ready}}());"

protocol ZHWebViewBridgeProtocol:class {
    func zh_evaluateJavaScript(javaScriptString: String,
                               completionHandler: ((AnyObject?,NSError?) -> Void)?)
}

extension ZHWebViewBridgeProtocol {
    func zh_unpackActions(handler:([ZHBridgeAction] -> Void)) {
        zh_evaluateJavaScript("ZHBridge.Core.getAndClearJsActions()") { (res:AnyObject?, _:NSError?) in
            handler(ZHBridgeHelper.unpackActions(res))
        }
    }
    
    func zh_callHander(handlerName:String, args:[AnyObject], callback:(AnyObject? -> Void)? = nil) {
        let handlerInfo = [
            "name": handlerName,
            "args": args,
            "argsCount": args.count
        ]
        let data = ZHBridgeHelper.serializeData(handlerInfo)
        zh_evaluateJavaScript("ZHBridge.Core.callJsHandler('\(data)')") { (res:AnyObject?, _:NSError?) in
            callback?(ZHBridgeHelper.unpackResult(res))
        }
    }
    
    func zh_callback(result:ZHBridgeActionResult) {
        if !result.validCallBack {
            return
        }
        let callbackInfo:[String:AnyObject] = [
            "id": result.actionId,
            "status": result.status,
            "args": (result.result == nil) ? [NSNull()] : [result.result!]
        ]
        let data = ZHBridgeHelper.serializeData(callbackInfo)
        zh_evaluateJavaScript("ZHBridge.Core.callbackJs('\(data)')", completionHandler: nil)
    }
}

extension UIWebView: ZHWebViewBridgeProtocol {
    func zh_evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        let res = stringByEvaluatingJavaScriptFromString(javaScriptString)
        completionHandler?(res, nil)
    }
}

extension WKWebView: ZHWebViewBridgeProtocol {
    func zh_evaluateJavaScript(javaScriptString: String, completionHandler: ((AnyObject?, NSError?) -> Void)?) {
        evaluateJavaScript(javaScriptString, completionHandler: completionHandler)
    }
}

class ZHBridgeWKScriptMessageHandler:NSObject, WKScriptMessageHandler {
    private(set) weak var bridge:ZHWebViewBridge!
    
    init(bridge:ZHWebViewBridge) {
        super.init()
        self.bridge = bridge
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let bridge = bridge else {
            return
        }
        
        if let body = message.body as? String where message.name == ZHBridgeName && !body.isEmpty{
            bridge.handlerActions(ZHBridgeHelper.unpackActions(body))
        }
    }
}

// MARK: extention UIWewView the ability like WKWebView
class ZHScriptMessage {
    private(set) var name:String = ""
    private(set) var body:AnyObject?
    
    init(name:String, body:AnyObject?) {
        self.name = name
        self.body = body
    }
}

protocol ZHScriptMessageHandler:class {
    func handle(message:ZHScriptMessage)
}

class ZHBridgeWBScriptMessageHandler:ZHScriptMessageHandler {
    private(set) weak var bridge:ZHWebViewBridge!
    
    init(bridge:ZHWebViewBridge) {
        self.bridge = bridge
    }
    
    
    func handle(message: ZHScriptMessage) {
        guard let bridge = bridge else {
            return
        }
        
        if let body = message.body as? String where message.name == ZHBridgeName && !body.isEmpty{
            dispatch_async(dispatch_get_main_queue(), {
                bridge.handlerActions(ZHBridgeHelper.unpackActions(body))
            })
        }
    }
}

@objc protocol ZHBridgeScriptMessageHandlerWrapperJSExport: JSExport {
    func postMessage(body:AnyObject?)
}
class ZHBridgeScriptMessageHandlerWrapper:NSObject, ZHBridgeScriptMessageHandlerWrapperJSExport {
    private(set) var name:String = ""
    private(set) var handler:ZHScriptMessageHandler
    
    init(name:String, handler:ZHScriptMessageHandler) {
        self.name = name
        self.handler = handler
    }
    
    func postMessage(body:AnyObject?) {
        handler.handle(ZHScriptMessage.init(name: name, body: body))
    }
}

class ZHWebViewDelegate:NSObject, UIWebViewDelegate {
    private weak var delegate:UIWebViewDelegate?
    private var webViewDidFinishLoadBlock:(UIWebView -> Void)?
    var webViewShouldStartLoadWithRequestBlock:((UIWebView, NSURLRequest) -> Bool)?
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return  webViewShouldStartLoadWithRequestBlock?(webView, request) ?? (delegate?.webView?(webView, shouldStartLoadWithRequest: request, navigationType: navigationType) ?? true)
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        delegate?.webViewDidStartLoad?(webView)
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        webViewDidFinishLoadBlock?(webView)
        delegate?.webViewDidFinishLoad?(webView)
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        delegate?.webView?(webView, didFailLoadWithError: error)
    }
}

class ZHWebViewContentController:NSObject {
    private(set) var webView:UIWebView!
    private(set) var delegateUnderProxy = false
    private(set) weak var jsContext:JSContext?
    private let delegate = ZHWebViewDelegate()
    private(set) var messageHandlers:[String:AnyObject] = [:]
    private(set) var pluginScripts = [String]()
    private var contextKVO:Int = 0
    private let jsContextPath = "documentView.webView.mainFrame.javaScriptContext"
    private let delegatePath = "delegate"
    
    
    init(webView:UIWebView, proxyDelegate:Bool = true) {
        super.init()
        
        delegateUnderProxy = proxyDelegate
        
        let jsContextPath = self.jsContextPath
        self.webView = webView
        jsContext = webView.valueForKeyPath(jsContextPath) as? JSContext
        webView.addObserver(self, forKeyPath: jsContextPath, options: [.Initial, .New], context: &contextKVO)
        
        delegate.webViewDidFinishLoadBlock = { [weak self] (wb:UIWebView) in
            if let context = webView.valueForKeyPath(jsContextPath) as? JSContext where self?.jsContext !== context {
                self?.updateJsContext(context)
            }
        }
        updateWebViewDelegate(webView.delegate)
        webView.addObserver(self, forKeyPath: delegatePath, options: [.Initial, .New], context: &contextKVO)
    }
    
    deinit {
        webView?.removeObserver(self, forKeyPath: jsContextPath)
        webView?.removeObserver(self, forKeyPath: delegatePath)
        webView = nil
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &contextKVO else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        
        if keyPath == jsContextPath {
            if let context = change?[NSKeyValueChangeNewKey] as? JSContext where jsContext !== context {
                updateJsContext(context)
            }
        } else if keyPath == delegatePath {
            updateWebViewDelegate(change?[NSKeyValueChangeNewKey] as? UIWebViewDelegate)
        }
    }
    
    private func updateWebViewDelegate(delegate:UIWebViewDelegate?) {
        if delegate !== self.delegate {
            self.delegate.delegate = delegate
        }

        if delegateUnderProxy && webView.delegate !== self.delegate {
            webView.delegate = self.delegate
        }
    }
    
    private func updateJsContext(context:JSContext) {
        jsContext = context
        setupUserPlugins()
        updateMessgeHandler()
    }
    
    private func updateMessgeHandler() {
        jsContext?.setObject(messageHandlers, forKeyedSubscript: "zhbridge_messageHandlers")
    }
    
    func addScriptMessageHandler(scriptMessageHandler: ZHScriptMessageHandler, name: String) {
        messageHandlers[name] = ZHBridgeScriptMessageHandlerWrapper.init(name: name, handler: scriptMessageHandler)
        updateMessgeHandler()
    }
    
    private func setupUserPlugins() {
        for script in pluginScripts {
            jsContext?.evaluateScript(script)
        }
    }
    
    func addUserPlugin(script:String) {
        if !Set(pluginScripts).contains(script) {
            pluginScripts.append(script)
            jsContext?.evaluateScript(script)
        }
    }
    
    func removeUserPlugin(script:String) {
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

public class ZHWebViewBridge {
    private var handlerMapper:[String: ([AnyObject] -> (Bool, [AnyObject]?))] = [:]

    private(set) weak var bridge:ZHWebViewBridgeProtocol?

    private var contentController:ZHWebViewContentController?   // UIWeview only

    private init(){}

    deinit {
        teardown()
    }
    
    /// initial delegate of UIWebView
    public var delegate:UIWebViewDelegate? {
        return contentController?.delegate.delegate
    }
    
    /**
     tear down your bridge, if you call this method, your bridge will not work any more.
     Note: If you bridge for UIWebView, you should call this method, to release reference of UIWebView
     */
    public func teardown() {
        handlerMapper = [:]
        contentController = nil
        bridge = nil
    }
    
    /**
     register a handler to handle js call
     
     - parameter handlerName: handler name, unique to identify native handler
     - parameter callback:    native call back to handler js call. Input args array, return tuple. tuple.0 indicate handle status, tuple.1 args array to pass to js callback
     */
    public func registerHandler(handlerName:String, callback:([AnyObject] -> (Bool, [AnyObject]?))) {
        handlerMapper[handlerName] = callback
    }
    /**
     call js handler register in js
     
     - parameter handlerName: handler name, unique to identify js handler
     - parameter args:        args that will be pass to registered js handler
     - parameter callback:    callback method after js handler
     */
    public func callJsHandler(handlerName:String, args:[AnyObject], callback:(AnyObject? -> Void)? = nil) {
        bridge?.zh_callHander(handlerName, args: args, callback: callback)
    }
    
    /**
     adds a user script.
     Note:  If bridge for UIWebView, you shoul avoid to use this method, in case it will not work as you aspect
     
     - parameter source: The user plugin script to add.
     
     - returns: whether plugin added success
     */
    public func addUserPluginScript(source:String) -> Bool {
        if let _ = bridge as? UIWebView {
            contentController?.addUserPlugin(source)
        } else if let webview = bridge as? WKWebView {
            webview.configuration.userContentController.addUserScript(WKUserScript.init(source: source, injectionTime: .AtDocumentStart, forMainFrameOnly: true))
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
    public class func bridge(webView:UIWebView, proxyDelegate:Bool = true) -> ZHWebViewBridge {
        let bridge = ZHWebViewBridge()
        bridge.bridge = webView
        
        let messageHandler = ZHBridgeWBScriptMessageHandler.init(bridge: bridge)
        let contentController = ZHWebViewContentController.init(webView: webView, proxyDelegate: proxyDelegate)
        contentController.addUserPlugin(ZHWebViewBridgeJS)
        contentController.addScriptMessageHandler(messageHandler, name: ZHBridgeName)
        contentController.delegate.webViewShouldStartLoadWithRequestBlock = { (wb:UIWebView, request:NSURLRequest) -> Bool in
            return !bridge.handleRequest(request)
        }
        bridge.contentController = contentController
        
        return bridge
    }
    
    /**
     check whether request can handle bridge
     
     - parameter request: request
     
     - returns: true can handle, false can not handle
     */
    private final func canHandle(request: NSURLRequest) -> Bool {
        if let scheme = request.URL?.scheme where scheme.caseInsensitiveCompare(ZHBridgeName) == .OrderedSame {
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
    public func handleRequest(request: NSURLRequest) -> Bool {
        if canHandle(request) {
            bridge?.zh_unpackActions({ [weak self](actions:[ZHBridgeAction]) in
                guard let sself = self where !actions.isEmpty else {
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
    public class func bridge(webView:WKWebView, injectBridgeJs:Bool = true) -> ZHWebViewBridge {
        let bridge = ZHWebViewBridge()
        bridge.bridge = webView
        
        if injectBridgeJs {
            webView.configuration.userContentController.addUserScript(WKUserScript.init(source: ZHWebViewBridgeJS, injectionTime: .AtDocumentStart, forMainFrameOnly: true))
        }
        let messageHandler = ZHBridgeWKScriptMessageHandler.init(bridge: bridge)
        webView.configuration.userContentController.addScriptMessageHandler(messageHandler, name: ZHBridgeName)
        
        return bridge
    }
    
    private func handlerActions(actions:[ZHBridgeAction]) {
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
