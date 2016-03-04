//
//  OddVideoCollection.swift
//  PokerCentral
//
//  Created by Patrick McConnell on 7/31/15.
//  Copyright (c) 2015 Patrick McConnell. All rights reserved.
//

import UIKit
@objc(OddVideoCollection)
class OddVideoCollection: OddMediaObject {
  
  override var contentTypeString: String { return "videoCollection" }
  
  var videoIds: Array<String>?
  
  var numberOfVideos : Int {
    return videoIds != nil ? videoIds!.count : 0
  }
  
  class func videoCollectionFromJson(json: jsonObject) -> OddVideoCollection {
    let newVideoCollection = OddVideoCollection()
    newVideoCollection.configureWithJson(json)
    newVideoCollection.defaultTitle = "Odd Networks Video Collection"
    newVideoCollection.defaultSubtitle = "Another fine video collection from Odd Networks"
    
    return newVideoCollection
  }
  
  override func configureWithJson(json: jsonObject) {
    super.configureWithJson(json)
    addAdditionalMetaData(json)
  }
  
  func addAdditionalMetaData(json: jsonObject) {
    if let relationships = json["relationships"] as? jsonObject,
      videos = relationships["videos"] as? jsonObject,
      data = videos["data"] as? Array<jsonObject> {
        self.videoIds = Array()
        for video: jsonObject in data {
          if let videoId = video["id"] as? String {
            self.videoIds!.append(videoId)
          }
        }
    }
  }
  
}
