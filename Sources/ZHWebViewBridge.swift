//
//  ZHWebViewBridge.swift
//  WebViewBridge.Swift
//
//  Created by travel on 16/6/19.
//  Copyright © 2016年 travel. All rights reserved.
//

import UIKit
import WebKit
import JavaScriptCore

class ZHBridgeAction {
    var actionId:Int64 = 0
    var name:String = ""
    var args:[AnyObject] = []
    
    init(actionId:Int64, name:String, args:[AnyObject]) {
        self.actionId = actionId
        self.name = name
        self.args = args
    }
    
    var isValid: Bool {
        return !name.isEmpty
    }
}

class ZHBridgeActionResult {
    var actionId:Int64 = 0
    var status = true
    var result:AnyObject?
    
    init(actionId:Int64) {
        self.actionId = actionId
    }
    
    init(actionId:Int64, status:Bool, result:AnyObject?) {
        self.actionId = actionId
        self.status = status
        self.result = result
    }
}

public class ZHBridgeHelper {
    public final class func serializeData(data:AnyObject) ->String {
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
                    let action = ZHBridgeAction.init(actionId: actionId.longLongValue, name: name, args: args)
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


private let ZHWebViewBridgeJS = "var ZHBridge=window.ZHBridge||{};window.ZHBridge=ZHBridge;ZHBridge.Core=ZHBridge.Core||(function(){var callbackId=1;var callbacks={};var actionQueue=[];var createBridge=function(){var iFrame;iFrame=document.createElement(\"iframe\");iFrame.setAttribute(\"src\",\"ZHBridge://__BRIDGE_LOADED__\");iFrame.setAttribute(\"style\",\"display:none;\");iFrame.setAttribute(\"height\",\"0px\");iFrame.setAttribute(\"width\",\"0px\");iFrame.setAttribute(\"frameborder\",\"0\");document.body.appendChild(iFrame);setTimeout(function(){document.body.removeChild(iFrame)},0)};var callNativeHandler=function(){var actionName=arguments[0];var actionArgs=arguments[1]||[];var successCallback=arguments[2];var failCallback=arguments[3];var actionId=++callbackId;if(successCallback||failCallback){callbacks[actionId]={success:successCallback,fail:failCallback}}else{actionId=0}var action={id:actionId,name:actionName,args:actionArgs,argsCount:actionArgs.length};if(window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.ZHBridge&&window.webkit.messageHandlers.ZHBridge.postMessage){window.webkit.messageHandlers.ZHBridge.postMessage(JSON.stringify([action]))}else{if(window.zhbridge_messageHandlers&&window.zhbridge_messageHandlers.ZHBridge&&window.zhbridge_messageHandlers.ZHBridge.postMessage){window.zhbridge_messageHandlers.ZHBridge.postMessage(JSON.stringify([action]))}else{actionQueue.push(action);createBridge()}}};var getAndClearQueuedActions=function(){var json=JSON.stringify(actionQueue);actionQueue=[];return json};var callbackJs=function(){var data=arguments[0];if(!data){return}var callInfo=JSON.parse(data);var callbackId=callInfo[\"id\"];var status=callInfo[\"status\"];var args=callInfo[\"args\"];if(!callbackId||status==undefined||args==undefined){return}var callback=callbacks[callbackId];var success=callback[\"success\"];var fail=callback[\"fail\"];if(!callback){return}var result=undefined;if(status&&success){result=success.apply(this,args)}else{if(!status&&fail){result=fail.apply(this,args)}}return result!=undefined?JSON.stringify(result):undefined};var handlerMapper={};var callJsHandler=function(data){var callInfo=JSON.parse(data);var name=callInfo[\"name\"];var args=callInfo[\"args\"];var argsCount=callInfo[\"argsCount\"];if(!name||argsCount==undefined||argsCount!=args.length){return}var handler=handlerMapper[name];if(handler){var result=handler.apply(this,args);return result!=undefined?JSON.stringify(result):undefined}};var registerJsHandler=function(handlerName,callback){handlerMapper[handlerName]=callback};var ready=function(){var readyFunction=arguments[0];if(readyFunction){document.addEventListener(\"DOMContentLoaded\",readyFunction)}};return{getAndClearJsActions:getAndClearQueuedActions,callJsHandler:callJsHandler,callbackJs:callbackJs,registerJsHandler:registerJsHandler,callNativeHandler:callNativeHandler,ready:ready}}());var ZHBridge=window.ZHBridge||{};window.ZHBridge=ZHBridge;ZHBridge.Core=ZHBridge.Core||(function(){var callbackId=1;var callbacks={};var actionQueue=[];var createBridge=function(){var iFrame;iFrame=document.createElement(\"iframe\");iFrame.setAttribute(\"src\",\"ZHBridge://__BRIDGE_LOADED__\");iFrame.setAttribute(\"style\",\"display:none;\");iFrame.setAttribute(\"height\",\"0px\");iFrame.setAttribute(\"width\",\"0px\");iFrame.setAttribute(\"frameborder\",\"0\");document.body.appendChild(iFrame);setTimeout(function(){document.body.removeChild(iFrame)},0)};var callNativeHandler=function(){var actionName=arguments[0];var actionArgs=arguments[1]||[];var successCallback=arguments[2];var failCallback=arguments[3];var actionId=++callbackId;if(successCallback||failCallback){callbacks[actionId]={success:successCallback,fail:failCallback}}else{actionId=0}var action={id:actionId,name:actionName,args:actionArgs,argsCount:actionArgs.length};if(window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.ZHBridge&&window.webkit.messageHandlers.ZHBridge.postMessage){window.webkit.messageHandlers.ZHBridge.postMessage(JSON.stringify([action]))}else{if(window.zhbridge_messageHandlers&&window.zhbridge_messageHandlers.ZHBridge&&window.zhbridge_messageHandlers.ZHBridge.postMessage){window.zhbridge_messageHandlers.ZHBridge.postMessage(JSON.stringify([action]))}else{actionQueue.push(action);createBridge()}}};var getAndClearQueuedActions=function(){var json=JSON.stringify(actionQueue);actionQueue=[];return json};var callbackJs=function(){var data=arguments[0];if(!data){return}var callInfo=JSON.parse(data);var callbackId=callInfo[\"id\"];var status=callInfo[\"status\"];var args=callInfo[\"args\"];if(!callbackId||status==undefined||args==undefined){return}var callback=callbacks[callbackId];var success=callback[\"success\"];var fail=callback[\"fail\"];if(!callback){return}var result=undefined;if(status&&success){result=success.apply(this,args)}else{if(!status&&fail){result=fail.apply(this,args)}}return result!=undefined?JSON.stringify(result):undefined};var handlerMapper={};var callJsHandler=function(data){var callInfo=JSON.parse(data);var name=callInfo[\"name\"];var args=callInfo[\"args\"];var argsCount=callInfo[\"argsCount\"];if(!name||argsCount==undefined||argsCount!=args.length){return}var handler=handlerMapper[name];if(handler){var result=handler.apply(this,args);return result!=undefined?JSON.stringify(result):undefined}};var registerJsHandler=function(handlerName,callback){handlerMapper[handlerName]=callback};var ready=function(){var readyFunction=arguments[0];if(readyFunction){document.addEventListener(\"DOMContentLoaded\",readyFunction)}};return{getAndClearJsActions:getAndClearQueuedActions,callJsHandler:callJsHandler,callbackJs:callbackJs,registerJsHandler:registerJsHandler,callNativeHandler:callNativeHandler,ready:ready}}());"

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
        zh_evaluateJavaScript("ZHBridge.Core.callJsHandler('\(ZHBridgeHelper.serializeData(handlerInfo))')") { (res:AnyObject?, _:NSError?) in
            callback?(ZHBridgeHelper.unpackResult(res))
        }
    }
    
    func zh_callback(result:ZHBridgeActionResult) {
        if !result.validCallBack {
            return
        }
        let callbackInfo:[String:AnyObject] = [
            "id": NSNumber.init(longLong: result.actionId),
            "status": result.status,
            "args": (result.result == nil) ? [NSNull()] : [result.result!]
        ]
        zh_evaluateJavaScript("ZHBridge.Core.callbackJs('\(ZHBridgeHelper.serializeData(callbackInfo))')", completionHandler: nil)
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
        
        if let body = message.body as? String where message.name == "ZHBridge" && !body.isEmpty{
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
        
        if let body = message.body as? String where message.name == "ZHBridge" && !body.isEmpty{
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

class ZHWebViewContentController:NSObject {
    private(set) weak var webView:UIWebView!
    private(set) weak var jsContext:JSContext?
    private(set) var messageHandlers:[String:AnyObject] = [:]
    private var contextKVO:Int = 0
    private let jsContextPath = "documentView.webView.mainFrame.javaScriptContext"
    
    init(webView:UIWebView) {
        super.init()
        self.webView = webView
        webView.addObserver(self, forKeyPath: jsContextPath, options: [.Initial, .New], context: &contextKVO)
    }
    
    deinit {
        webView?.removeObserver(self, forKeyPath: jsContextPath)
        webView = nil
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &contextKVO else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        
        if keyPath == jsContextPath {
            if let context = change?[NSKeyValueChangeNewKey] as? JSContext {
                jsContext = context
                updateMessgeHandler()
            }
        }
    }
    
    private func updateMessgeHandler() {
        jsContext?.setObject(messageHandlers, forKeyedSubscript: "zhbridge_messageHandlers")
    }
    
    func addScriptMessageHandler(scriptMessageHandler: ZHScriptMessageHandler, name: String) {
        messageHandlers[name] = ZHBridgeScriptMessageHandlerWrapper.init(name: name, handler: scriptMessageHandler)
        updateMessgeHandler()
    }
    
    func addUserScript(script:String) {
        jsContext?.evaluateScript(script)
    }
}


public class ZHWebViewBridge {
    private var handlerMapper:[String: ([AnyObject] -> (Bool, [AnyObject]?))] = [:]

    private(set) weak var bridge:ZHWebViewBridgeProtocol?

    
    private init(){}
    
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
    
    
    // MARK: for UIWebView
    public class func bridge(webView:UIWebView) -> ZHWebViewBridge {
        let bridge = ZHWebViewBridge()
        bridge.bridge = webView
        
        let messageHandler = ZHBridgeWBScriptMessageHandler.init(bridge: bridge)
        let contentController = ZHWebViewContentController.init(webView: webView)
        contentController.addUserScript(ZHWebViewBridgeJS)
        contentController.addScriptMessageHandler(messageHandler, name: "ZHBridge")
        
        return bridge
    }
    
    /**
     check whether request can handle bridge
     
     - parameter request: request
     
     - returns: true can handle, false can not handle
     */
    private final func canHandle(request: NSURLRequest) -> Bool {
        let scheme = "ZHBridge"
        if let url = request.URL where url.scheme.caseInsensitiveCompare(scheme) == .OrderedSame {
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
    @available(*, deprecated=0.3, message="due to usage of JavaScriptCore, no need to embed js manually")
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
        webView.configuration.userContentController.addScriptMessageHandler(messageHandler, name: "ZHBridge")
        
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