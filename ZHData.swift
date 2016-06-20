//
//  ZHData.swift
//  WebViewBridge.Swift
//
//  Created by travel on 16/6/20.
//  Copyright © 2016年 travel. All rights reserved.
//

import Foundation

class ZHData {
    let imageUrls = [
        "http://pic94.nipic.com/file/20160409/11284670_185122899000_2.jpg",
        "http://pic83.nipic.com/file/20151117/11284670_111631760000_2.jpg",
        "http://pic100.nipic.com/file/20160602/19302950_100602826000_2.jpg",
        "http://pic100.nipic.com/file/20160606/19302950_144229953000_2.jpg",
        "http://pic101.nipic.com/file/20160617/9748710_145625068000_2.jpg"
    ]
    
    var imageFolder:String {
        let path = (NSTemporaryDirectory() as NSString).stringByAppendingPathComponent("image")
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            _ = try? NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }
    
    var htmlData: String {
        let path = NSBundle.mainBundle().pathForResource("html_template.html", ofType: nil)!
        return NSString.init(data: NSFileManager.defaultManager().contentsAtPath(path)!, encoding: NSUTF8StringEncoding) as! String
    }
    
    static let instance = ZHData()
    
    
    
    func downloadImage(urlPath:String, handler:(String -> Void)) {
        // urlPath.hashValue may confict, here just from example
        let fileName = "download_image_\(urlPath.hashValue)"
        let targetPath = (imageFolder as NSString).stringByAppendingPathComponent(fileName)
        
        if NSFileManager.defaultManager().fileExistsAtPath(targetPath) {
            handler(fileName)
        } else {
            NSURLSession.sharedSession().dataTaskWithURL(NSURL.init(string: urlPath)!, completionHandler: { (data:NSData?, _:NSURLResponse?, _:NSError?) in
                data?.writeToFile(targetPath, atomically: true)
                dispatch_async(dispatch_get_main_queue(), {
                    handler(fileName)
                })
             }).resume()
        }
    }
    
}
