//
//  OddImage.swift
//  OddSDK
//
//  Created by Patrick McConnell on 6/16/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import UIKit

public struct OddImage {
  /// The URL to the image. Required
  public var url: String
  /// the optional mimeType of the image. Required
  public var mimeType: String?
  
  /// An optional value for the width of the image
  public var width: Int?
  
  /// An optional value for the height of the image
  public var height: Int?
  
  /// An label for the image
  public var label: String?
  
  fileprivate var _image: UIImage?
  
  init(url: String, mimeType: String?, width: Int?, height: Int?, label: String?) {
    self.url = url
    self.mimeType = mimeType
    self.width = width
    self.height = height
    self.label = label
    self._image = nil
  }
  
  public static func imageFromJson(_ json: jsonObject) -> OddImage? {
    guard let url       = json["url"] as? String else {
        return nil
    }
    
    let label     = json["label"] as? String
    let mimeType  = json["mimeType"] as? String
    let width     = json["width"] as? Int
    let height    = json["height"] as? Int
    
    
    return OddImage(url: url, mimeType: mimeType, width: width, height: height, label: label)
  }
  
  /// Loads the image asset
  ///
  /// Checks if the `_image` asset is already present returning it if so.
  ///
  /// If the asset is not already loaded the asset is fetched and upon success the
  /// callback closure is executed with the image as a parameter
  ///
  /// parameter callback: A closure taking a `UIImage` as a parameter to be executed when the image is loaded
  public func image(_ callback: @escaping (UIImage?) -> Void  ) {
    let storedImage = getImage()
    if let image = storedImage {
      callback(image)
    } else {
      
      let request = NSMutableURLRequest(url: URL(string: self.url)!)
      let session = URLSession.shared
      request.httpMethod = "GET"
      
      let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error -> Void in
        
        if let e = error as? URLError {
          if e.code == .notConnectedToInternet {
            NotificationCenter.default.post(Notification(name: OddConstants.OddImageLoadDidFail, object: e) )
          }
          callback(nil)
          return
        }
        
        if let res = response as? HTTPURLResponse {
          if res.statusCode == 200 {
            if let imageData = data {
              if let image = UIImage(data: imageData) {
                self.setImage(image)
                callback(image)
              } else {
                callback(nil)
              }
            }
          } else {
            callback(nil)
          }
        }
      })
      task.resume()
    }
  }
  
  func setImage(_ image: UIImage) {
    OddContentStore.sharedStore.imageCache.setObject(image, forKey: self.url as NSString)
  }
  
  func getImage() -> UIImage? {
    return OddContentStore.sharedStore.imageCache.object(forKey: self.url as NSString)
  }

}
