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
  var url: String
  /// the mimeType of the image. Required
  var mimeType: String
  
  /// An optional value for the width of the image
  var width: Int?
  
  /// An optional value for the height of the image
  var height: Int?
  
  /// An optional label for the image
  var label: String?
  
  public static func imageFromJson(_ json: jsonObject) -> OddImage? {
    guard let url       = json["url"] as? String,
      let mimeType  = json["mimeType"] as? String else {
        return nil
    }
    
    let width     = json["width"] as? Int
    let height    = json["height"] as? Int
    let label     = json["label"] as? String
    
    return OddImage(url: url, mimeType: mimeType, width: width, height: height, label: label)
  }
}
