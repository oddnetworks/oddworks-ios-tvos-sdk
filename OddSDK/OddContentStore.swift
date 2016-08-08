//
//  OddContentStore.swift
//
//
//  Created by Patrick McConnell on 8/6/15.
//  Copyright (c) 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

/// A type alias used to identify typical JSON response objects
public typealias jsonObject = Dictionary<String, AnyObject>
public typealias jsonArray = Array<jsonObject>

enum OddFeatureType {
  case Media
  case Collection
  case Promotion
}

/// Class to load and store the various OddMediaObject types
/// Applications should only maintain one instance of the
/// content store and access that instance through the
/// `sharedStore()` instance variable
/// 
/// ### Concepts
/// 
/// #### Media Objects
///
/// All objects stored in the Content Store are `OddMediaObjects` 
/// Typically only subclasses of `OddMediaObject` are used in client applications.
///
/// In order to have a dynamic system for handling views all
/// stored objects descend from `OddMediaObject` This allows
/// a viewController to display a collection of media objects
/// while querying the objects themselves for informaton such 
/// as how to render in a `tableviewcell` or what action to 
/// perform when that object is selected
/// 
/// Refer to `OddMediaObject`, `OddVideo`, `OddMediaObjectCollection`
/// for more information
///
/// #### Views
///
/// In the world of the `OddContentStore` a view is a collection
/// of `OddMediaObjects` to be displayed together in a client app
/// 
/// For example the `initialize()` method will load the apps configuration
/// and then fetch the 'home' view. This 'home' view will be the
/// collection of media objects the customer has selected to be displayed
/// first to the user. Any view may have related objects, objects linked to
/// from that view, that may also be included in the view reponse from the server
/// when related items are found for a view the content store will fetch those items
/// and store them for use when needed.
///
/// A view may contain one or more `OddMediaObjects` from a single `OddVideo` to
/// mulitple `OddMediaObjectCollections` with many levels of nested media objects
///
/// #### Collections
/// Collections typically of the type `OddMediaObjectCollection` are
/// groups of `OddMediaObjects` The collection in addition to holding 
/// and `Array` of the objects will also have information useful for
/// presenting the collection to the user via the UI.
/// 
/// Collections can contain any type of media object or may be typed
/// to contain only specific object types. Currently there is only support
/// for generic collections, `OddArticle` or `OddEvent` typed collections
/// See `OddMediaObjectCollectionType` enum defined in `OddMediaObjectCollection`
///
/// Refer to `OddMediaObjectCollection` for more information
///
/// #### Featured Items
///
/// A client will have many `OddMediaObjects` in its library but
/// certain media objects will be `Featured.` When an object is
/// `Featured` this is an indication that the client app should 
/// display this content in a prominent location or way. 
///
/// For example featured content would be displayed on the first
/// screen visible when the app launches
@objc public class OddContentStore: NSObject {
  
  /// A generic method to locate an `OddMediaObject` of a given type from the
  /// stored objects
  /// - parameter idToFind: id of the object to be found
  /// - parameter mediaType: the type of object to be found
  ///
  /// MediaType should be passed in as a class instance: OddMediaObject()
  /// ```Swift
  ///    storedMediaObjectWithId( "999", OddVideo() )
  /// ```
  /// - returns: the media object found or nil
  func storedMediaObjectWithId<T>(idToFind: String?, mediaType: T) -> T? {
    if let id = idToFind {
      return mediaObjects.filter({ (mediaObject) -> Bool in
        return mediaObject.id == id && mediaObject is T
      }).first as? T
    } else {
      return nil
    }
  }

  /// A generic method to locate an `Array` of `MediaObjects` of a given type from the
  /// stored objects
  /// - parameter idsToFind: an `Array` of ids of the objects to be found
  /// - parameter mediaType: the type of objects to be found
  ///
  /// MediaType should be passed in as a class instance: OddMediaObject()
  /// ```Swift
  ///    storedMediaObjectsWithId( ["777", "888", "999"], OddVideo() )
  /// ```
  /// - returns: an `Array` of the media objects found or nil
  func storedMediaObjectsWithIds<T>(idsToFind: Array<String>?, mediaType: T) -> Array<T>? {
    var collections: Array<T> = Array()
    idsToFind?.forEach({ (id) -> () in
      if let foundObject = storedMediaObjectWithId( id, mediaType: mediaType ) {
        collections.append(foundObject)
      }
    })
    
    return collections.isEmpty ? nil : collections
  }
  
  /// A singleton instance of the `OddContentStore`
  /// in order to keep only one instance of the content library loaded all 
  /// access to the media objects should be made through this singleton instance
  static public let sharedStore = OddContentStore()
  
  /// The master collection of `OddMediaObject`s
  /// any object loaded from the server is stored in this `Set`
  public var mediaObjects: Set<OddMediaObject> = Set()
  
  /// A `singleton` instance of our API client used to communicate with the server
  /// and parse responses and/or errors
  /// publicly accessible via the SDK. Client applications will need to set the
  /// `authToken` instance variable on `API` before using the SDK
  public var API = APIService.sharedService
  
  /// The applications configurable settings as loaded from the server
  public var config: OddConfig?
  
  /// Determines whether objects in the object store can expire based
  /// on a cache time to live set via HTTP header from server responses
  public var useCacheTTL: Bool = true
  /// when fetched

  #if os(iOS)
  /// The `Array` of ids for the `OddArticles` in the media objects store.
  /// No public access. Clients should access articles via
  /// the `articles` instance variable
  var articleIds: Array<String>?
  
  // The `Array` of `OddArticles` stored in the media objects store
  public var articles: Array<OddArticle>? {
    get {
      return storedMediaObjectsWithIds(articleIds, mediaType: OddArticle() )
    }
  }
  
  /// The `Array` of ids for the `OddEvents` in the media objects store.
  /// No public access. Clients should access events via
  /// the `events` instance variable
  var eventIds: Array<String>?
  
  // The `Array` of `OddEvents` stored in the media objects store
  public var events: Array<OddEvent>? {
    get {
      return storedMediaObjectsWithIds(eventIds, mediaType: OddEvent() )
    }
  }
  
  /// The `Array` of ids for the `OddExternals` in the media objects store.
  /// No public access. Clients should access externals via
  /// the `externals` instance variable
  var externalIds: Array<String>?
  
  // The `Array` of `OddExternals` stored in the media objects store
  public var externals: Array<OddExternal>? {
    get {
      return storedMediaObjectsWithIds(externalIds, mediaType: OddExternal() )
    }
  }
#endif
  /// The `Array` of ids for the `OddMediaObjects` in the menu stored in the media objects store.
  /// No public access. Clients should access menu items via
  /// the `menuItems` instance variable
  var menuItemIds: Array<String>?
  
    // The `Array` of `OddMediabjects` in the menu stored in the media objects store
  public var menuItems: Array<OddMediaObject>? {
    return storedMediaObjectsWithIds(menuItemIds, mediaType: OddMediaObject())
  }
  
  
  #if os(iOS)
  /// The `OddMenu` instance stored in the content store
  /// The menu will be one or more `OddMenuItemCollections`
  /// Currently only provided for iOS apps. No tvOS support
  /// at this time
  ///
  /// Refer to `OddMenu`, `OddMenuItemCollection`
  var homeMenu: OddMenu = OddMenu()
  #endif
  
  var imageCache = NSCache()
  
  ///  Our instance variable used to determine if the content store has completed it
  /// initial load of the `OddConfig`, the home view and any related media objects
  var initialDataLoadComplete = false
  
  func showVersionInfo(beta beta: Bool = false) {
    
    var platform = "iOS"
    #if tvOS
      platform = "tvOS"
    #endif
    
    let betaString = beta ? " BETA" : ""
      
    OddLogger.info("### OddSDK\(betaString) ###")
    if beta {
      OddLogger.warn("### Not for production Applications ###")
    }
  }
  
  func showSDKInfo() {
    #if BETA
      showVersionInfo(beta: true)
    #else
      showVersionInfo()
    #endif
  }
  
  /// Initializes the content store. If the config is successfully loaded upon completion the
  /// OddContentStore instance will contain an instance of OddConfig. 
  /// Initialize will call back the closure passed with the success and/or any error
  /// encountered during the loading of the config
  public func initialize(success: (Bool, NSError?) -> Void) {
    OddLogger.info("INITIALIZE CONTENT STORE")
    self.showSDKInfo()
    fetchConfig { (result, error) in
      success(result, error)
    }
  }
  
  public func resetStore() {
    // yes we could do the following:
    // OddContentStore.sharedStore = OddContentStore()
    // but that would require changing our singleton instance to a var
    // which users could overwrite. so no.
    self.config = nil
    self.mediaObjects.removeAll()
    #if iOS
      self.articleIds?.removeAll()
      self.eventIds?.removeAll()
      self.externalIds?.removeAll()
      self.homeMenu = nil
    #endif
    self.menuItemIds?.removeAll()
  }

  /// Private helper to process errors in a standard way
  ///
  /// If a notification type is passed that notification will be posted
  /// The error will be logged via OddLogger.error
  /// The closure passed will be called with nil for the media object and the error
  ///
  /// - parameter errorMsg: `String`  a message to log/report for the error condition
  /// - parameter errorCode: `Int` a code for the error
  /// - parameter notification: `String`? an optional notification name. If present the notification is posted
  /// - parameter callback: `(OddMediaObject?, NSError) -> Void`  a closure to be executed. The object passed will be nil. 
  /// The error will be configured according to the params
  ///
  func returnError(errorMsg: String, errorCode: Int, notification: String?, callback: (OddMediaObject?, NSError) -> Void) {
    let errorStr = "Error: \(errorMsg)"
    let error = NSError(domain: "Odd", code: errorCode, userInfo: ["error": errorMsg])
    if let notification = notification {
      NSNotificationCenter.defaultCenter().postNotificationName(notification, object: self, userInfo: nil)
    }
    OddLogger.error(errorStr)
    callback(nil, error)
  }
  
  /// Parses the config response for the JWT containing a user
  /// if found the jwt is written to the user defaults and used as
  /// the authToken for future requests
  func parseUserJWT(json: jsonObject) {
    guard let data = json["data"] as? jsonObject,
      attribs = data["attributes"] as? jsonObject,
      jwt = attribs["jwt"] as? String else { return }
    NSUserDefaults.standardUserDefaults().setObject(jwt, forKey: "OddUserAuthToken")
    NSUserDefaults.standardUserDefaults().synchronize()
  }
  
  /// Loads the OddConfig instance for the OddContentStore
  ///
  /// Not intended to be called by the user. This method is called from
  /// the `initialize` method
  ///
  /// - parameter success: `(Bool, NSError?) -> Void`  a closure to be executed. The Bool will be the success of loading the config
  /// if an error is encountered loading the config it will be passed as well
  ///
  /// Callback will be executed with the config instance or nil
  /// depending on the success of the loading call
  func fetchConfig(success: (Bool, NSError?)->Void ) {
    OddLogger.info("FETCHING CONFIG")
    API.get( nil, url: "config") { ( response, err ) -> () in
      if let error = err {
        OddLogger.error("Error fetching config: \(error.localizedDescription)")
        NSNotificationCenter.defaultCenter().postNotificationName(OddConstants.OddErrorFetchingConfigNotification, object: self, userInfo: nil)
        success(false, error)
      } else {
        guard let json = response as? jsonObject,
          let newConfig = OddConfig.configFromJson(json) else {
            OddLogger.error("Error fetching config: unable to parse config")
            NSNotificationCenter.defaultCenter().postNotificationName(OddConstants.OddErrorFetchingConfigNotification, object: self, userInfo: nil)
            let error = NSError(domain: "Odd", code: 103, userInfo: ["error": "unable to parse config"])
            success(false, error)
            return
        }
        self.config = newConfig
        self.parseUserJWT(json)
        OddLogger.info("Successfully loaded config")
        NSNotificationCenter.defaultCenter().postNotificationName(OddConstants.OddFetchedConfigNotification, object: self, userInfo: ["config" : newConfig])
        success(true, nil)
      }
    }
  }
  
  
  /// Locates media objects by type and id
  ///
  /// - parameter type: String the media object type to find
  /// - parameter ids: Ids of the object(s) to be found
  /// - parameter callback: `(Array<AnyObject>) -> Void` a callback executed once the search is complete
  /// The `Array` passed to `callback` will either contain the entities matching the query or be empty
  /// if no entities were found
  ///
  /// Note: Objects are first looked for in the local cache (`mediaObjects`) if no matching object is
  /// found in the cache the server will be polled for a matching object. If no objects
  /// are found an empty `array` is returned
  public func objectsOfType( type: OddMediaObjectType, ids : Array<String>, include: String?, callback: (Array<OddMediaObject>, Array<NSError>?) -> Void )  {
    
    if self.mediaObjects.isEmpty {
      fetchObjectsOfType(type, ids: ids, include: include, callback: { (objects, errors) -> () in
        callback(objects, errors)
      })
    } else {
      var objects: Array<OddMediaObject> = Array()
      var unMatchedIds: Array<String> = []
      var localErrors: Array<NSError> = []
      
      for id: String in ids {
        var match = false
        // check store for existing media objects
       
        for object in self.mediaObjects {
          
          if let objectId = object.id  {
            let correctType = object.objectIsOfType(type)
            let idMatch = objectId == id
            
            if idMatch && !correctType {
              // consider this one dealt with
              localErrors.append( NSError(domain: "Odd", code: 110, userInfo: ["error" : "\(id) exists but is not of type \(type.toString())"]) )
              match = true
              break
            }
            
            if idMatch  && correctType && useCacheTTL && !object.cacheHasExpired {
              objects.append(object)
              match = true
              break
            }
          }
        }
        // Add to list of objectsIds that need fetching
        if !match {
          unMatchedIds.append(id)
        }
      }
      
      //fetch the batch of unmatched objects
      fetchObjectsOfType(type, ids: unMatchedIds, include: nil, callback: { (fetchedObjects, errors) -> () in
        fetchedObjects.forEach({ (obj) -> () in
          objects.append(obj)
        })
        
        if errors != nil {
          localErrors.appendContentsOf(errors!)
        }
        
        callback(objects, localErrors.isEmpty ? nil : localErrors)
      })
    }
  }
  
  /// Calls the API server to locate media objects of a type with a given id
  ///
  /// - parameter type: String the media object type as defined on the server
  /// ("video" or "collection") are the currently supported types
  /// - parameter id: `Array<String>` the id of the entity to be fetched
  /// - parameter callback: `( Array<OddMediaObject> ) -> Void` a callback executed once the search is complete
  /// The array passed to `callback` will either contain the entities matching the query or be empty
  /// if no entities wer found
  public func fetchObjectsOfType ( type: OddMediaObjectType, ids: Array<String>, include: String?, callback: ( Array<OddMediaObject>, Array<NSError>? ) -> () ) {
    var responseArray: Array<OddMediaObject> = Array()
    var errorArray: Array<NSError> = Array()
    
    if ids.isEmpty { callback(responseArray, nil) }
    
    var callbackCount = 0
    for id : String in ids {
      fetchObjectType(type, id: id, include: include, callback: { (item, err) -> () in
        callbackCount += 1
        
        if let error = err {
          errorArray.append(error)
          return
        }
        
        switch item {
        case is OddView:
          if let foundView = item as? OddView {
            responseArray.append(foundView)
          }
        case is OddVideo:
          if let foundVideo = item as? OddVideo {
            responseArray.append(foundVideo)
          }
        case is OddMediaObjectCollection:
          if let foundCollection = item as? OddMediaObjectCollection {
            responseArray.append(foundCollection)
          }
        default: break
        }
        
        let errors: Array<NSError>? = errorArray.count == 0 ? nil : errorArray
        if callbackCount == ids.count { callback(responseArray, errors) }
      })
    }
  }
  
  /// Calls the API server to locate a single media object of a type with a given id
  ///
  /// - parameter type: `String` the media object type as defined on the server
  /// ("video" or "collection") are the currently supported types
  /// - parameter id: `String` the id of the entity to be fetched
  /// - parameter callback: `(AnyObject?) -> Void` a callback executed once the search is complete
  /// The object passed to `callback` will either be the entity matching the query or be nil
  /// if no entity was found
  ///
  /// Note: the return type of `AnyObject?` will be changing to `OddMediaObject?` in a future
  /// update
  ///
  /// See also: `fetchObjectsOfType ( type: String, ids: Array<String>, callback: ( Array<AnyObject> ) -> Void )`
  /// to fetch multiple objects of a given type
  public func fetchObjectType( type: OddMediaObjectType, id: String, include: String?, callback: ( OddMediaObject?, NSError? ) -> Void ) {
    
    var urlStr = "\(type.toString() )s/\(id)"
    if let include = include { urlStr = "\(urlStr)?include=\(include)" }
    
    API.get(nil , url: urlStr ) { (response, error) -> () in
      if error != nil {
        self.returnError("Error fetching \(type.toString()): \(id)", errorCode: 105, notification: nil, callback: callback)
      } else {
        if let json = response as? jsonObject,
          data = json["data"] as? jsonObject {
          
          guard let mediaObject = self.buildObjectFromJson(data, ofType: type) else {
            let error = NSError(domain: "Odd", code: 108, userInfo: ["error" : "unable to build media object"])
            callback(nil, error )
            return
          }
          
          if let included = json["included"] as? jsonArray {
            self.buildIncludedMediaObjects(included, cacheTime: data["cacheTime"] as? Int )
          }
          
          switch type {
          case .View:
            if mediaObject is OddView { callback(mediaObject, nil) }
          case .Video:
            if mediaObject is OddVideo { callback(mediaObject, nil) }
          case .Collection:
            if mediaObject is OddMediaObjectCollection { callback(mediaObject, nil) }
          default:
            self.returnError("Error fetching \(type.toString()): \(id)", errorCode: 105, notification: nil, callback: callback)
//            callback(nil)
          }
          
          
        } // if
      }
    }
  }
  
  /// Calls the API server to locate media objects that match the url query param
  ///
  /// - parameter type: String the media object type as defined on the server
  /// ("video" or "collection") are the currently supported types
  /// - parameter query: `Array<String>` the url query used to request data from the API
  /// - parameter callback: `( Array<OddMediaObject> ) -> Void` a callback executed once the search is complete
  /// The array passed to `callback` will either contain the entities matching the query or be empty
  /// if no entities were found
  public func fetchObjectsWithQuery ( type: OddMediaObjectType, query: String, callback: ( Array<OddMediaObject>, NSError? ) -> () ) {
    API.get(nil, url: query) { (response, error) -> () in
      if error != nil {
        OddLogger.error("Error fetching objects with query")
        callback([], error)
      } else {
        guard let json = response as? jsonObject,
          data = json["data"] as? jsonArray else {
            let error = NSError(domain: "Odd", code: 107, userInfo: ["error" : "unable to parse response"])
            callback([], error)
            return
        }
        var mediaObjects: Array<OddMediaObject> = []
        for jsonObject in data {
          mediaObjects.append(type.toObject(jsonObject))
        }
        callback(mediaObjects, nil)
      }
    }
  }
  
  /// Creates an `OddMediaObject` of specified type from supplied json
  ///
  /// - parameter json: The raw json to use in object creation
  /// - parameter type: type of object to be created
  ///
  func buildObjectFromJson(json: jsonObject, ofType type: OddMediaObjectType) -> OddMediaObject? {
    var mediaObject: OddMediaObject?
    switch type {
    case .View:
      mediaObject = OddView.viewFromJson(json)
    case .Video:
      mediaObject = OddVideo.videoFromJson(json)
    case .Collection:
      mediaObject = OddMediaObjectCollection.mediaCollectionFromJson(json)
    default:
      break
    } // switch
    if let object = mediaObject {
      self.mediaObjects.insert(object)
      return object
    } else {
      return nil
    }
  }
  
  /// builds any json objects in the 'include' field of a json 
  /// response.
  ///
  /// - parameter json: `jsonArray` an array of `jsonObject`s describing the included objects
  ///
  func buildIncludedMediaObjects(json: jsonArray, cacheTime: Int?) {
    json.forEach { (someJson) in
      var objectJson = someJson
      guard let typeString = objectJson["type"] as? String else { return }
      if let type = OddMediaObjectType.fromString(typeString) {
        if let cacheTime = cacheTime { objectJson["cacheTime"] = cacheTime }
        buildObjectFromJson(objectJson, ofType: type)
      }
    }
  }
  
  // MARK: - Helpers
  
  /// Returns the media object in the `mediaStore` with a specified id
  ///
  /// - parameter id: `String` the id of the entity to be found
  ///
  /// - returns: `OddMediaObject`? the object found or nil in none is found
  ///
  /// Note: This method only searches the `mediaStore` for cached objects
  ///
  /// See also: `objectsOfType( type: String, ids : Array<String>, callback: (Array<AnyObject>) ->Void )`
  /// to search the cache and the Server
  public func mediaObjectWithId(id: String) -> OddMediaObject? {
    for mediaObject in mediaObjects {
      if mediaObject.id == id { return mediaObject }
    }
    return nil
  }
  
  /// Returns an array of media objects in the `mediaStore` with a specified ids
  ///
  /// - parameter ids: `Array<String>` an array of ids of the entities to be found
  ///
  /// - returns: `Array<OddMediaObject>`? the objects found or nil in none are found
  ///
  /// Note: This method only searches the `mediaStore` for cached objects
  ///
  /// See also: `objectsOfType( type: String, ids : Array<String>, callback: (Array<AnyObject>) ->Void )`
  /// to search the cache and the Server
  public func mediaObjectsWithIds(ids: Array<String>) -> Array<OddMediaObject>? {
    var objects = Array<OddMediaObject>()
    ids.forEach { (id) -> () in
      if let obj = mediaObjectWithId(id) {
        objects.append(obj)
      }
    }
    return objects.count > 0 ? objects : nil
  }
  
  public func searchForTerm(term: String, onResults: ( videos: Array<OddVideo>?, collections: Array<OddMediaObjectCollection>? ) -> Void ) {
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: OddConstants.OddStartedSearchNotification, object: nil))
    })
    
    API.get( nil, url: "search?q=\(term)") { ( response, error ) -> () in
      if let _ = error {
        print("Error fetching search results")
        onResults (videos: nil, collections: nil)
      } else {
        if let json = response as? jsonObject {
          if let data = json["data"] as? Array<jsonObject> {
            var videoResults = Array<OddVideo>()
            var collectionResults = Array<OddMediaObjectCollection>()
            for result: jsonObject in data {
              guard let typeStr = result["type"] as? String,
               let mediaObjectType = OddMediaObjectType.fromString( typeStr ) else { continue }
              guard let resultObject = self.buildObjectFromJson(result, ofType: mediaObjectType) else { break }
              
              self.mediaObjects.insert(resultObject)
              
              switch resultObject {
              case is OddVideo :
                videoResults.append(resultObject as! OddVideo)
              case is OddMediaObjectCollection :
                collectionResults.append(resultObject as! OddMediaObjectCollection)
              default:
                break
              }
            }
            OddLogger.info("Found \(videoResults.count) videos and \(collectionResults.count) collections")
            onResults(videos: videoResults, collections: collectionResults)
          }
        }
      }
    }
  }
  
  /// A helper method to provide information about the media objects
  /// currently in the `mediaStore`
  ///
  /// - returns: `String` a string with information about the contents of the `mediaStore`
  ///
  /// Example:
  /// 
  /// ```Swift 
  ///     print( "\( mediaObjectInfo() )" )
  /// ```
  /// displays the `mediaStore` info to the console
  public func mediaObjectInfo() -> String {
    let videos = self.mediaObjects.filter { (obj) -> Bool in
      return obj is OddVideo
    }
    
    let collections = self.mediaObjects.filter { (obj) -> Bool in
      return obj is OddMediaObjectCollection
    }
    
    let promotions = self.mediaObjects.filter { (obj) -> Bool in
      return obj is OddPromotion
    }
    
  #if os(iOS)
    let articles = self.mediaObjects.filter { (obj) -> Bool in
      return obj is OddArticle
    }
    
    let events = self.mediaObjects.filter { (obj) -> Bool in
      return obj is OddEvent
    }
    
    let externals = self.mediaObjects.filter { (obj) -> Bool in
      return obj is OddExternal
    }
  #endif
    
  #if os(iOS)
    let result = "Content Store contains \(videos.count) Videos, \(collections.count) Collections, \(promotions.count) Promotions, \(articles.count) Articles, \(events.count) Events, \(externals.count) Externals"
  #else
    let result = "Content Store contains \(videos.count) Videos, \(collections.count) Collections, \(promotions.count) Promotions"
  #endif
    return result
  }
  
}