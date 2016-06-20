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
        if let infoString = obj as? String, infos = ZHBridgeHelper.deserializeData(infoString) as? [[String: AnyObject]] {
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
}

protocol ZHWebViewBridgeProtocol:class {
    func zh_evaluateJavaScript(javaScriptString: String,
                               completionHandler: ((AnyObject?,NSError?) -> Void)?)
}

extension ZHBridgeActionResult {
    var validCallBack: Bool {
        return actionId != 0
    }
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
            callback?(res)
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
    static let messageHandlerName = "zhWebViewBridge"
    
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
    private lazy var brigeQueue = dispatch_queue_create("bridgeQueue", DISPATCH_QUEUE_SERIAL)
    private var handlerMapper:[String: ([AnyObject] -> (Bool, AnyObject?))] = [:]
    
    private(set) weak var bridge:ZHWebViewBridgeProtocol?
    private(set) var messageHandler:ZHBridgeWKScriptMessageHandler!
    
    
    private init(){}
    
    func registerHandler(handlerName:String, callback:([AnyObject] -> (Bool, AnyObject?))) {
        handlerMapper[handlerName] = callback
    }
    
    func callHander(handlerName:String, args:[AnyObject], callback:(AnyObject? -> Void)? = nil) {
        bridge?.zh_callHander(handlerName, args: args, callback: callback)
    }
    
    
    // MARK: for UIWebView
    class func bridge(webView:UIWebView) -> ZHWebViewBridge {
        let bridge = ZHWebViewBridge()
        bridge.bridge = webView
        
        return bridge
    }
    
    func canHandler(request: NSURLRequest) -> Bool {
        let scheme = "zhWebViewBridge"
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