//
//  OddMediaObjectCollection.swift
//  Odd-iOS
//
//  Created by Patrick McConnell on 11/30/15.
//  Copyright © 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

enum OddMediaObjectCollectionType {
  case generic
  case articles
  case events
}

/// A media object collection is a collection of `OddMediaObject`s
///
/// An `OddMediaObjectCollection` may hold any other `OddMediaObject`s
@objc open class OddMediaObjectCollection: OddMediaObject {
  
  override var contentTypeString: String { return "mediaObjectCollection" }
  
  override var cellReuseIdentifier: String { return "mediaInfoCell" }
  override var cellHeight: CGFloat { return 80 }
  
  var showAccessoryView = true
  
  var type: OddMediaObjectCollectionType = .generic
//  var objectInfos: Array<MediaObjectInfo>?
  var objectInfos: Dictionary<String, OddMediaObjectType> = [:]
  
  /// For each `OddMediaObject` stored in the collection we store only
  /// the `OddMediaObject`'s id.
  open var objectIds: Array<String> {
    return Array(objectInfos.keys)
  }
  
  open var objectTypes: Array<OddMediaObjectType> {
    return Array(objectInfos.values)
  }
  
  /// The number of `OddMediaObject`s in the collection
  open var numberOfObjects: Int {
    return objectInfos.count
  }
  
  var typesOfObjects: Set<OddMediaObjectType> {
    var types = Set<OddMediaObjectType>()
    objectTypes.forEach { (type) -> () in
      types.insert(type)
    }
    return types
  }
  
  class func mediaCollectionFromJson(_ json: jsonObject) -> OddMediaObjectCollection {
    let newMediaObjectCollection = OddMediaObjectCollection()
    //set default header to empty
    newMediaObjectCollection.headerHeight = 0

    newMediaObjectCollection.configureWithJson(json)
    newMediaObjectCollection.defaultTitle = "Odd Networks Media Object Collection"
    newMediaObjectCollection.defaultSubtitle = "Another fine media object collection from Odd Networks"
    
    return newMediaObjectCollection
  }
  
  override func configureWithJson(_ json: jsonObject) {
    super.configureWithJson(json)
    addAddtitionalMetaData(json)
  }
  
  func addAddtitionalMetaData(_ json: jsonObject) {
//    print("JSON: \(json)")
    
    if let relationships = json["relationships"] as? jsonObject,
      let mediaObjects = relationships["entities"] as? jsonObject,
      let data = mediaObjects["data"] as? Array<jsonObject> {
        self.objectInfos.removeAll()
        
        data.forEach({ (mediaObjectJson) -> () in
          
          if let id =  mediaObjectJson["id"] as? String,
            let type = mediaObjectJson["type"] as? String {
              
              //temporary hack to get article and event headers
              if type == "article" {
                self.headerHeight = 30
                self.headerText = "News"
                self.type = .articles
              } else if type == "event" {
                self.headerHeight = 30
                self.headerText = "Events"
                self.type = .events
              }
              
              guard let mediaType = OddMediaObjectType.fromString(type) else { return }
//              let info = MediaObjectInfo(id: id, type: OddMediaObjectType(rawValue: type)! )
//              let info = MediaObjectInfo(id: id, type: mediaType )
//              self.objectInfos!.append(info)
              self.objectInfos[id] = mediaType
          }
        })
    }
  }
  
  open func objectTypeForId(_ id: String) -> OddMediaObjectType? {
    return objectInfos[id]
  }
  
  open func idsOfAllObjectsOfType(_ type: OddMediaObjectType) -> Array<String> {
    var objects = Array<String>()
    objectIds.forEach { (id) -> () in
      if type == objectInfos[id] {
        objects.append(id)
      }
    }
    return objects
  }
  
  open func fetchAllObjects( _ callback: @escaping (Array<OddMediaObject>) -> Void ) {
    var objects = Array<OddMediaObject>()
    
    var count = 0
    
    typesOfObjects.forEach { (type) -> () in
      let ids = idsOfAllObjectsOfType(type)
      if !ids.isEmpty {
        OddContentStore.sharedStore.objectsOfType(type, ids: ids, callback: { (fetchedObjects) -> () in
          objects.append( contentsOf: fetchedObjects )
          count += 1
          if count == self.typesOfObjects.count {
            callback(objects)
          }
        })
      }
    }
  }
  
}
