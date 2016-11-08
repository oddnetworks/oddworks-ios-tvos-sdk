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
  
  public var watchlist: Set<OddRelationship> = Set()
  
  static public let current = OddViewer()
  
  public static func fetchWatchlist(onResults: @escaping ( _ success: Set<OddRelationship>?, _ error: NSError? ) -> Void ) {
    DispatchQueue.main.async(execute: { () -> Void in
      NotificationCenter.default.post(Notification(name: OddConstants.OddStartedWatchlistFetchNotification, object: nil))
    })
    
    if OddViewer.current.id.isEmpty {
      let errorMessage = "No User ID found for watchlist fetch"
      let error = OddContentStore.sharedStore.buildError(errorMessage, errorCode: 108, notification: nil)
      onResults(nil, error)
    }
    
    OddContentStore.sharedStore.API.get( nil, url: "viewers/\(OddViewer.current.id)/relationships/watchlist") { ( response, error ) -> () in
      if let _ = error {
        let errorMessage = "Error fetching watchlist"
        let error = OddContentStore.sharedStore.buildError(errorMessage, errorCode: 109, notification: nil)
        OddLogger.error(errorMessage)
        onResults (nil, error)
      } else {
          guard let json = response as? jsonObject else {
            let errorMessage = "Error parsing watchlist json"
            let error = OddContentStore.sharedStore.buildError(errorMessage, errorCode: 110, notification: nil)
            OddLogger.error(errorMessage)
            onResults (nil, error)
            return
          }
        
        if let data = json["data"] as? Array<jsonObject> {
          OddViewer.current.buildWatchListFromJson(json: data)
        } else if let data = json["data"] as? jsonObject {
//        print("WATCHLIST: \(data)")
          OddViewer.current.buildWatchListFromJson(json: [data])
        } else {
          let errorMessage = "Error parsing watchlist json"
          let error = OddContentStore.sharedStore.buildError(errorMessage, errorCode: 110, notification: nil)
          OddLogger.error(errorMessage)
          onResults (nil, error)
          return
        }
        onResults(OddViewer.current.watchlist, nil)
      }
    }
  }

  public static func watchlistMediaObjects(onComplete: @escaping ( _ mediaObjects: Array<OddMediaObject>, _ errors: Array<NSError> ) -> Void ) {
    if OddViewer.current.watchlist.isEmpty {
      onComplete(Array(), Array())
    }
    
    var results = Array<OddMediaObject>()
    var errorResults = Array<NSError>()
    
    var checkedCollections = false
    var checkedVideos = false
    
    if let collections = OddViewer.current.watchlistItemsOfType(type: .collection) {
      let collectionIds = collections.map {$0.id}
      
      if !collectionIds.isEmpty {
        OddContentStore.sharedStore.objectsOfType(.collection, ids: collectionIds, include: "entities", callback: { (objects, errors) in
          checkedCollections = true
          if errors != nil {
            errorResults += errors!
            print("objects error")
            return
          }
          results += objects
          
          if checkedVideos {
            onComplete(results, errorResults)
          }
        })
      } else {
        checkedCollections = true
        if checkedVideos {
          onComplete(results, errorResults)
        }
      }
    } else {
        checkedCollections = true
    }
    
    if let videos = OddViewer.current.watchlistItemsOfType(type: .video) {
      let videoIds = videos.map {$0.id}
      
      if !videoIds.isEmpty {
        OddContentStore.sharedStore.objectsOfType(.video, ids: videoIds, include: nil, callback: { (objects, errors) in
          checkedVideos = true
          if errors != nil {
            errorResults += errors!
            print("objects video error")
            return
          }
          results += objects
          
          if checkedCollections {
            onComplete(results, errorResults)
          }
        })
      } else {
        checkedVideos = true
        if checkedCollections {
          onComplete(results, errorResults)
        }
      }
    } else {
      checkedVideos = true
    }
  }
  
  fileprivate func watchlistItemsOfType(type: OddMediaObjectType) -> Array<OddRelationship>? {
    let objects = OddViewer.current.watchlist.filter { return $0.mediaObjectType == type }
    
    if objects.isEmpty {
      return nil
    }
    
    return objects
  }
  
  
  
  
  func buildWatchListFromJson(json : jsonArray) {
    OddLogger.info("Found \(json.count) watchlist items to build")
    
    json.forEach { (item) in
      guard let id = item["id"] as? String,
        let rawType = item["type"] as? String,
        let objectType = OddMediaObjectType.fromString(rawType) else {
          OddLogger.error("Incorrect watchlist item data")
          return
      }
      
      let watchItem = OddRelationship(id: id, mediaObjectType: objectType)
      self.watchlist.insert(watchItem)
      OddLogger.info("Added \(watchItem.id) to watchlist")
    }
  }
  
  func watchlistContains(mediaObject: OddMediaObject) -> Bool {
    guard let type = mediaObject.mediaObjectType,
      let id = mediaObject.id else { return false }
    let item = OddRelationship(id: id, mediaObjectType: type)
    return self.watchlist.contains(item)
  }
  
}

