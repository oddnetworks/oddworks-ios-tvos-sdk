//
//  OddViewer.swift
//  OddSDK
//
//  Created by Patrick McConnell on 10/26/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import Foundation

public class OddViewer {
  public var id: String {
    get {
        let id = UserDefaults.standard.string(forKey: OddConstants.kUserIdKey)
      if id == nil {
        return ""
      } else {
        return id!
      }
    }
  }
  
  public var watchList: Set<OddRelationship> = Set()
  
  static public let current = OddViewer()
  
  func addMediaObjectToWatchList(_ mediaObject: OddMediaObject) -> Bool {
    guard let id = mediaObject.id,
      let objectType = OddMediaObjectType.fromString(mediaObject.contentTypeString) else {
        return false
    }
    
    let watchItem = OddRelationship(id: id, mediaObjectType: objectType)
    self.watchList.insert(watchItem)
    return true
  }
}

