//
//  OddMediaObjectCollection.swift
//  Odd-iOS
//
//  Created by Patrick McConnell on 11/30/15.
//  Copyright © 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

enum OddMediaObjectCollectionType {
  case Generic
  case Articles
  case Events
}

struct MediaObjectInfo {
  var id: String
  var type : OddMediaObjectType
}

/// A media object collection is a collection of `OddMediaObject`s
///
/// An `OddMediaObjectCollection` may hold any other `OddMediaObject`s
@objc public class OddMediaObjectCollection: OddMediaObject {
  
  override var contentTypeString: String { return "mediaObjectCollection" }
  
  override var cellReuseIdentifier: String { return "mediaInfoCell" }
  override var cellHeight: CGFloat { return 80 }
  
  var showAccessoryView = true
  
  var type: OddMediaObjectCollectionType = .Generic
  var objectInfos: Array<MediaObjectInfo>?
  
  /// For each `OddMediaObject` stored in the collection we store only
  /// the `OddMediaObject`'s id.
  public var objectIds: Array<String> {
    var ids = Array<String>()
    objectInfos?.forEach({ (info) -> () in
      ids.append(info.id)
    })
    return ids
  }
  
  
  /// The number of `OddMediaObject`s in the collection
  public var numberOfObjects: Int {
    return objectInfos != nil ? objectInfos!.count : 0
  }
  
  class func mediaCollectionFromJson(json: jsonObject) -> OddMediaObjectCollection {
    let newMediaObjectCollection = OddMediaObjectCollection()
    //set default header to empty
    newMediaObjectCollection.headerHeight = 0

    newMediaObjectCollection.configureWithJson(json)
    newMediaObjectCollection.defaultTitle = "Odd Networks Media Object Collection"
    newMediaObjectCollection.defaultSubtitle = "Another fine media object collection from Odd Networks"
    
    return newMediaObjectCollection
  }
  
  override func configureWithJson(json: jsonObject) {
    super.configureWithJson(json)
    addAddtitionalMetaData(json)
  }
  
  func addAddtitionalMetaData(json: jsonObject) {
//    print("JSON: \(json)")
    
    
    if let relationships = json["relationships"] as? jsonObject,
      mediaObjects = relationships["entities"] as? jsonObject,
      data = mediaObjects["data"] as? Array<jsonObject> {
        self.objectInfos = Array()
        
        data.forEach({ (mediaObjectJson) -> () in
          
          if let id =  mediaObjectJson["id"] as? String,
            type = mediaObjectJson["type"] as? String {
              
              //temporary hack to get article and event headers
              if type == "article" {
                self.headerHeight = 30
                self.headerText = "News"
                self.type = .Articles
              } else if type == "event" {
                self.headerHeight = 30
                self.headerText = "Events"
                self.type = .Events
              }
              
              guard let mediaType = OddMediaObjectType.fromString(type) else { return }
//              let info = MediaObjectInfo(id: id, type: OddMediaObjectType(rawValue: type)! )
              let info = MediaObjectInfo(id: id, type: mediaType )
              self.objectInfos!.append(info)
          }
        })
    }
  }
  
}
