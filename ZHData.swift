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
        let path = (NSTemporaryDirectory() as NSString).appendingPathComponent("image")
        if !FileManager.default.fileExists(atPath: path) {
            _ = try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        return path
    }
    
    var htmlData: String {
        let path = Bundle.main.path(forResource: "html_template.html", ofType: nil)!
        return NSString.init(data: FileManager.default.contents(atPath: path)!, encoding: String.Encoding.utf8.rawValue) as! String
    }
    
    static let instance = ZHData()
    
    
    
    func downloadImage(_ urlPath:String, handler:@escaping ((String) -> Void)) {
        // urlPath.hashValue may confict, here just from example
        let fileName = "download_image_\(urlPath.hashValue)"
        let targetPath = (imageFolder as NSString).appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: targetPath) {
            handler(fileName)
        } else {
            URLSession.shared.dataTask(with: URL.init(string: urlPath)!, completionHandler: { (data:Data?, _:URLResponse?, _:Error?) in
                try? data?.write(to: URL(fileURLWithPath: targetPath), options: [.atomic])
                DispatchQueue.main.async(execute: {
                    handler(fileName)
                })
             }).resume()
        }
    }
    
}
