//
//  ZHWebViewBridge.swift
//  WebViewBridge.Swift
//
//  Created by travel on 16/6/19.
//  Copyright © 2016年 travel. All rights reserved.
//

import UIKit
import WebKit

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

class ZHBridgeHelper {
    class func serializeData(data:AnyObject) ->String {
        if let json = try? NSJSONSerialization.dataWithJSONObject(data, options: NSJSONWritingOptions.init(rawValue: 0)) {
            return NSString.init(data: json, encoding: NSUTF8StringEncoding) as! String
        }
        return ""
    }
    
    class func deserializeData(data:String) -> AnyObject? {
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


let ZHWebViewBridgeJS = "var ZHWVBridge=window.ZHWVBridge||{};window.ZHWVBridge=ZHWVBridge,ZHWVBridge.Core=ZHWVBridge.Core||function(){var e=1,t={},i=[],r=function(){var e;e=document.createElement(\"iframe\"),e.setAttribute(\"src\",\"ZHWVBridge://__BRIDGE_LOADED__\"),e.setAttribute(\"style\",\"display:none;\"),e.setAttribute(\"height\",\"0px\"),e.setAttribute(\"width\",\"0px\"),e.setAttribute(\"frameborder\",\"0\"),document.body.appendChild(e),setTimeout(function(){document.body.removeChild(e)},0)},n=function(){var n=arguments[0],s=arguments[1]||[],a=arguments[2],d=arguments[3],o=++e;a||d?t[o]={success:a,fail:d}:o=0;var g={id:o,name:n,args:s,argsCount:s.length};window.webkit&&window.webkit.messageHandlers&&window.webkit.messageHandlers.ZHWVBridge&&window.webkit.messageHandlers.ZHWVBridge.postMessage?window.webkit.messageHandlers.ZHWVBridge.postMessage(JSON.stringify([g])):(i.push(g),r())},s=function(){var e=JSON.stringify(i);return i=[],e},a=function(){var e=arguments[0];if(e){var i=JSON.parse(e),r=i.id,n=i.status,s=i.args;if(r&&void 0!=n&&void 0!=s){var a=t[r],d=a.success,o=a.fail;if(a){var g=void 0;return n&&d?g=d.apply(this,s):!n&&o&&(g=o.apply(this,s)),void 0!=g?JSON.stringify(g):void 0}}}},d={},o=function(e){var t=JSON.parse(e),i=t.name,r=t.args,n=t.argsCount;if(i&&void 0!=n&&n==r.length){var s=d[i];if(s){var a=s.apply(this,r);return void 0!=a?JSON.stringify(a):void 0}}},g=function(e,t){d[e]=t},u=function(){var e=arguments[0];e&&document.addEventListener(\"DOMContentLoaded\",e)};return{getAndClearJsActions:s,callJsHandler:o,callbackJs:a,registerJsHandler:g,callNativeHandler:n,ready:u}}();"

protocol ZHWebViewBridgeProtocol:class {
    func zh_evaluateJavaScript(javaScriptString: String,
                               completionHandler: ((AnyObject?,NSError?) -> Void)?)
}

extension ZHWebViewBridgeProtocol {
    func zh_unpackActions(handler:([ZHBridgeAction] -> Void)) {
        zh_evaluateJavaScript("ZHWVBridge.Core.getAndClearJsActions()") { (res:AnyObject?, _:NSError?) in
            handler(ZHBridgeHelper.unpackActions(res))
        }
    }
    
    func zh_callHander(handlerName:String, args:[AnyObject], callback:(AnyObject? -> Void)? = nil) {
        let handlerInfo = [
            "name": handlerName,
            "args": args,
            "argsCount": args.count
        ]
        zh_evaluateJavaScript("ZHWVBridge.Core.callJsHandler('\(ZHBridgeHelper.serializeData(handlerInfo))')") { (res:AnyObject?, _:NSError?) in
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
        zh_evaluateJavaScript("ZHWVBridge.Core.callbackJs('\(ZHBridgeHelper.serializeData(callbackInfo))')", completionHandler: nil)
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
        bridge.messageHandler = self
    }
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        guard let bridge = bridge else {
            return
        }
        
        if let body = message.body as? String where message.name == "ZHWVBridge" && !body.isEmpty{
            bridge.handlerActions(ZHBridgeHelper.unpackActions(body))
        }
    }
}


public class ZHWebViewBridge {
    private var handlerMapper:[String: ([AnyObject] -> (Bool, [AnyObject]?))] = [:]
    
    private(set) weak var bridge:ZHWebViewBridgeProtocol?
    private(set) var messageHandler:ZHBridgeWKScriptMessageHandler!
    
    
    private init(){}
    
    func registerHandler(handlerName:String, callback:([AnyObject] -> (Bool, [AnyObject]?))) {
        handlerMapper[handlerName] = callback
    }
    /**
     call js handler register in js
     
     - parameter handlerName: handler name, unique to identifier js handler
     - parameter args:        args that will be pass to registered js handler
     - parameter callback:    callback method after js handler
     */
    func callJsHander(handlerName:String, args:[AnyObject], callback:(AnyObject? -> Void)? = nil) {
        bridge?.zh_callHander(handlerName, args: args, callback: callback)
    }
    
    
    // MARK: for UIWebView
    class func bridge(webView:UIWebView) -> ZHWebViewBridge {
        let bridge = ZHWebViewBridge()
        bridge.bridge = webView
        
        return bridge
    }
    
    func canHandler(request: NSURLRequest) -> Bool {
        let scheme = "ZHWVBridge"
        if let url = request.URL where url.scheme.caseInsensitiveCompare(scheme) == .OrderedSame {
            return true
        }
        return false
    }
    
    func handlerRequest(request: NSURLRequest) -> Bool {
        if canHandler(request) {
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
    class func bridge(webView:WKWebView) -> ZHWebViewBridge {
        let bridge = ZHWebViewBridge()
        bridge.bridge = webView
        bridge.messageHandler = ZHBridgeWKScriptMessageHandler.init(bridge: bridge)
        
        webView.configuration.userContentController.addUserScript(WKUserScript.init(source: ZHWebViewBridgeJS, injectionTime: .AtDocumentStart, forMainFrameOnly: true))
        webView.configuration.userContentController.addScriptMessageHandler(bridge.messageHandler, name: "ZHWVBridge")
        
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