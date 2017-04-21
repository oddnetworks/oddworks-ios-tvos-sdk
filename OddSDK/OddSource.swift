//
//  OddSource.swift
//  OddSDK
//
//  Created by Patrick McConnell on 9/19/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import UIKit

public struct OddSource {
  /// The URL to the image. Required
  public var url: String
  /// the optional container type. ex: hls
  public var container: String?
  /// the optional mimeType of the image
  public var mimeType: String?
  
  /// An optional value for the width of the source
  public var width: Int?
  
  /// An optional value for the height of the source
  public var height: Int?
  
  /// An label for the source
  public var label: String
  
  /// An optional value with the maximum bitrate for the stream
  public var maxBitrate: Int?
    
  public var sourceType: String?
    
  public var broadcasting: Bool = true
  
  public static func sourceFromJson(_ json: jsonObject) -> OddSource? {
    guard let url       = json["url"] as? String,
      let label = json["label"] as? String else {
        return nil
    }
    
    let mimeType        = json["mimeType"] as? String
    let container       = json["container"] as? String
    let width           = json["width"] as? Int
    let height          = json["height"] as? Int
    let maxBitrate      = json["maxBitrate"] as? Int
    let sourceType      = json["sourceType"] as? String
    let broadcasting    = json["broadcasting"] as! Bool
    
    
    return OddSource(url: url, container: container, mimeType: mimeType, width: width, height: height, label: label, maxBitrate: maxBitrate, sourceType: sourceType, broadcasting: broadcasting)
  }
}
