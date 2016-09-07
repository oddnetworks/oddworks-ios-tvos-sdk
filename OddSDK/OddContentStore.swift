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
  
  /// The the client app organization. A string identifying the app in metric logs
//  public var organizationId = "organizationID_not_configured"
  
  /// The applications configurable settings as loaded from the server
  public var config: OddConfig?
  
  /// Temporary object to hold to json response data during the parsing process
  var responseData: jsonObject?
  
  /// Temporary object to hold to json response data during the parsing process
  var included: Array<jsonObject>?
  
  /// The id for the featured `OddPromotion` object in the media objects store
  /// no public access. Clients should access the featuredPromotion via 
  /// the featuredPromotion instance variable
  var featuredPromotionId: String?
  
  /// The featured `OddPromotion` object to be displayed by client applications
  public var featuredPromotion: OddPromotion? {
    get {
      return storedMediaObjectWithId( featuredPromotionId, mediaType: OddPromotion() )
    }
  }
  
  /// The id for the featured `OddMediaObject` object in the media objects store
  /// Typically this is an `OddVideo` instance.
  /// no public access. Clients should access the featuredMediaObject via
  /// the featuredMediaObject instance variable
  var featuredMediaObjectId: String?
  
  /// The featured `OddMediaObject` to be displayed by client applications
  public var featuredMediaObject: OddMediaObject? {
    get {
      return storedMediaObjectWithId( featuredMediaObjectId, mediaType: OddMediaObject() )
    }
  }

  /// The ids for the featured `OddMediaObjectCollection`s in the media objects store
  ///
  /// no public access. Clients should access the featuredCollections via
  /// the featuredCollections instance variable
  var featuredCollectionIds: Array<String>?
  
  /// The featured `OddMediaCollections` to be displayed by client applications
  public var featuredCollections: Array<OddMediaObjectCollection>? {
    get {
      return storedMediaObjectsWithIds(featuredCollectionIds, mediaType: OddMediaObjectCollection() )
    }
  }
  
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
  

  /// Determines which view should be fetched via API.
  /// Depending on client apps need for authentication
  /// and a users authentication status we provide different
  /// views and related media objects
  var viewToLoad: String? {
    guard let config = self.config else { OddLogger.error("Error loading config. Unable to determine view"); return nil }
    
    if config.requiresAuthentication {
      switch OddGateKeeper.sharedKeeper.authenticationStatus {
      case .Authorized:
        return config.homeViewId
      default:
        return config.splashViewId
      }
    } else {
      return config.homeViewId
    }
  }
  
  ///  Our instance variable used to determine if the content store has completed it
  /// initial load of the `OddConfig`, the home view and any related media objects
  var initialDataLoadComplete = false
  
  func showVersionInfo(beta beta: Bool = false) {
    
    var platform = "iOS"
    #if tvOS
      platform = "tvOS"
    #endif
    
    let betaString = beta ? " BETA" : ""
      
    OddLogger.error("### OddSDK\(betaString) ###")
    if beta {
      OddLogger.error("### Not for production Applications ###")
    }
  }
  
  /// Initializes the content store. If the config is successfully loaded upon completion the
  /// OddContentStore instance will contain an instance of OddConfig. If the loading of the
  /// config is successful this method will call `fetchViewInfo()` to begin loading the home 
  /// view and associated objects
  public func initialize() {
    #if BETA
      showVersionInfo(beta: true)
    #else
      showVersionInfo()
    #endif
    OddLogger.info("INITIALIZE CONTENT STORE")
    fetchConfig { (newConfig) -> () in
      if newConfig != nil {
        OddMetricService.postAppInitMetric()
        self.fetchViewInfo()
      }
    }
  }
  
  public func resetStore() {
    // yes we could do the following:
    // OddContentStore.sharedStore = OddContentStore()
    // but that would require changing our singleton instance to a var
    // which users could overwrite. so no.
    self.config = nil
    self.mediaObjects.removeAll()
    self.responseData = nil
    self.included?.removeAll()
    self.featuredPromotionId = nil
    self.featuredMediaObjectId = nil
    self.featuredCollectionIds?.removeAll()
    #if iOS
      self.articleIds?.removeAll()
      self.eventIds?.removeAll()
      self.externalIds?.removeAll()
      self.homeMenu = nil
    #endif
    self.menuItemIds?.removeAll()
  }
  
  /// Loads the OddConfig instance for the OddContentStore
  ///
  /// Not intended to be called by the user. This method is called from
  /// the `initialize` method
  ///
  /// - parameter callback: `(OddConfig?) -> Void`  a closure to be executed upon completion
  ///
  /// Callback will be executed with the config instance or nil
  /// depending on the success of the loading call
  func fetchConfig( callback: (OddConfig?) -> Void ) {
    OddLogger.info("FETCHING CONFIG")
    API.get( nil, url: "config") { ( response, error ) -> () in
      if let e = error {
        OddLogger.error("Error fetching config: \(e.localizedDescription)")
        NSNotificationCenter.defaultCenter().postNotificationName(OddConstants.OddErrorFetchingConfigNotification, object: self, userInfo: nil)
        callback(nil)
      } else {
        if let json = response as? Dictionary<String, AnyObject> {
//          OddLogger.info("CONFIG: \(json)")
          if let newConfig = OddConfig.configFromJson(json) {
            self.config = newConfig
            callback(newConfig)
          } else {
            callback(nil)
          }
        }
      }
    }
  }
  
  /// Loads the applications menu and home views
  /// Begins by loading the `OddMenu` instance for this application
  /// if applicable. Then fetches the 'home' or main view as configured
  /// by the customer. See the explanation of `View` in the notes for
  /// `OddContentStore` above
  func fetchViewInfo(){
    #if os(iOS)
    loadMenuView { (complete) -> () in
      OddLogger.info("Menu view load completed? \(complete)")
      self.loadHomeView()
    }
    #else
      self.loadHomeView()
    #endif
  }
  
  /// Loads the inital application view
  ///
  /// If there is an error fetching the view information an `OddErrorFetchingHomeViewNotification`
  /// will be posted
  ///
  /// If the loading of the view data is successful additional parsing will occur and a notification will
  /// be posted later when the parsing process is complete
  func loadHomeView () {
    if let viewId = self.viewToLoad {
      self.API.get( nil, url: "views/\(viewId)?include=4") { (response, error) -> () in
        if error != nil {
          OddLogger.error("Error fetching view: \(viewId)")
          NSNotificationCenter.defaultCenter().postNotificationName(OddConstants.OddErrorFetchingHomeViewNotification, object: self, userInfo: nil)
        } else {
          OddLogger.info("Fetched View Info building object graph...")
          if let json = response as? jsonObject,
            data = json["data"] as? jsonObject,
            included = json["included"] as? Array<jsonObject> {
//              OddLogger.info("JSON: \(json)")
//                              OddLogger.info("VIEW DATA: \(data)")
              self.responseData = data
              //                OddLogger.info("INCLUDED: \(included)")
              self.included = included
              
              self.buildObjectGraph()
          }
        }
      }
    }
  }

  /// Loads the `OddMenu` instance for this application
  ///
  /// If there is an error loading the menu data an `OddErrorFetchingMenuViewNotification`
  /// will be posted
  ///
  /// - parameter callback: `(Bool) -> Void`  a closure to be executed upon completion
  ///
  /// Callback will be executed with the completion of the building of the menu.
  /// If the menu was successfully build callback will be called with `true`
  /// a callback with `false` indicates the menu was not build correctly
  ///
  /// Note: Currently this is not backed completely by server data. Requires
  /// further server side implementation
  func loadMenuView( callback: (Bool) -> () ) {
    #if os(iOS)
    if let viewId = self.config?.menuViewId {
      API.get(nil, url: "views/\(viewId)?include=2") { (response, error) -> () in
        if error != nil {
          OddLogger.error("Error fetching menu view: \(viewId)")
          NSNotificationCenter.defaultCenter().postNotificationName(OddConstants.OddErrorFetchingMenuViewNotification, object: self, userInfo: nil)
        } else {
          OddLogger.info("Fetched Menu View Info building object graph...")
          if let json = response as? jsonObject,
            data = json["data"] as? jsonObject,
            included = json["included"] as? Array<jsonObject> {
              OddLogger.info("menu data: \(data)")
              self.responseData = data
              self.included = included
              self.buildMenu(data) { (complete) in
                callback(true)
              }
          }
        }
      }
    } else {
      OddLogger.info("BUILDING DEFAULT MENU")
      buildDefaultMenu() { (complete) in
        callback(true)
      }
    }
    #else
      callback(true)
    #endif
  }

  
  /// Builds the `OddMediaObjects` in the view being loaded.
  ///
  /// All media objects built are stored in the `MediaStore` and
  /// accessible via the content stores instance variables
  ///
  /// Upon completion of the process of building the complete object graph,
  /// an OddContentStoreCompletedInitialLoadNotification will be posted
  /// The posting of this notification is not an indication of success,
  /// only that the process completed. An application should verify that
  /// `MediaStore` contains the expected `OddMediaObjects`
  func buildObjectGraph() {
    if let relationships = self.responseData?["relationships"] as? jsonObject {
      
      self.buildFeaturedMediaObject(relationships)
      
//      self.buildSplashCollection(relationships)
      
      self.buildFeaturedCollections(relationships)
      
      self.buildFeaturedPromotion(relationships)
      
    } // relationships
    
    if let included = self.included {
      OddLogger.info("******** HAVE INCLUDED ********")
      buildIncludedMediaObjects(included)
    } else {
      OddLogger.info("??????? NO INCLUDED ???????")
    }
    
    initialDataLoadComplete = true
    NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: OddConstants.OddContentStoreCompletedInitialLoadNotification, object: self) )
    OddLogger.info( "\( self.mediaObjectInfo() )")
  }
  
  /// Builds the `featuredMediaObject` for the current view
  ///
  /// Upon success an OddFeaturedMediaObjectLoadedNotification is posted
  ///
  /// - parameter json: `jsonObject` a `jsonObject` containing the data to be parsed
  func buildFeaturedMediaObject(json: jsonObject) {
    if let featuredMediaObject = json["featuredMedia"] as? jsonObject {
      if let data = featuredMediaObject["data"] as? jsonObject {
        if let itemId = data["id"] as? String,
          itemType = data["type"] as? String {
            if let newObjectJson = findJsonObjectOfType(itemType, id: itemId) {
              let result = objectFromJson(newObjectJson)
              if let object = result.object {
                self.featuredMediaObjectId = itemId
                self.mediaObjects.insert(object)
                NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: OddConstants.OddFeaturedMediaObjectLoadedNotification, object: self ) )
              }
            } // newObjectJson
        } // itemId
      }
    }
  }
  
  /*
  // do we need this???
  func buildSplashCollection(json: jsonObject) {
    if let splashCollection = json["splashCollection"] as? jsonObject,
      data = splashCollection["data"] as? jsonObject {
        if let itemId = data["id"] as? String {
          if let newObjectJson = findJsonObjectOfType("videoCollection", id: itemId) {
            let result = objectFromJson(newObjectJson)
            if let object = result.object as? OddMediaObject {
              self.splashCollectionId = itemId
              self.mediaObjects.insert(object)
              NSNotificationCenter.defaultCenter().postNotificationName("splashCollectionLoaded", object: self, userInfo: nil)
            }
          } //newObejctJson
        } //itemId
    }
  }
  */
  
  /// Builds the `featuredCollections` for the current view
  ///
  /// Upon completion, posts an OddFeaturedCollectionsLoadedNotification.
  /// Client applications can then call `featuredCollections` to determine
  /// the collections that were created
  ///
  /// - parameter json: `jsonObject` a `jsonObject` containing the data to be parsed
  ///
  /// Note: The server may return the featuredCollections as either an array of collections
  /// or a single collection. We handle both
  func buildFeaturedCollections(json: jsonObject) {
    
    func buildObjects(data: jsonObject) {
      if let itemId = data["id"] as? String,
        itemType = data["type"] as? String {
          if let newObjectJson = findJsonObjectOfType(itemType, id: itemId) {
            let result = objectFromJson(newObjectJson)
            
            if let mediaObjectCollection = result.object as? OddMediaObjectCollection,
              id = mediaObjectCollection.id {
                self.featuredCollectionIds?.append(id)
                self.mediaObjects.insert(mediaObjectCollection)
            }
          }
      }
    }
    
    if let featuredCollections = json["featuredCollections"] as? jsonObject {
      
      self.featuredCollectionIds = Array()

      if let json = featuredCollections["data"] as? jsonArray {
        json.forEach({ (data) -> () in
          buildObjects(data)
        })
      } else if let data = featuredCollections["data"] as? jsonObject {
        buildObjects(data)
      }
      
    } // featured collections
    
    NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: OddConstants.OddFeaturedCollectionsLoadedNotification, object: self ) )
    OddLogger.info("Created \(self.featuredCollectionIds?.count) featured collections")
  }
  
  /// Builds the `featuredPromotion` for the current view
  ///
  /// Upon success, posts an OddFeaturedPromotionLoadedNotification
  ///
  /// - parameter json: `jsonObject` a `jsonObject` containing the data to be parsed
  func buildFeaturedPromotion(json: jsonObject) {
    if let featuredPromo = json["promotion"] as? jsonObject,
      data = featuredPromo["data"] as? jsonObject,
      promoId = data["id"] as? String {
        if let promoJson = findJsonObjectOfType("promotion", id: promoId) {
          let newPromo = OddPromotion.promotionFromJson(promoJson)
          if let meta = featuredPromo["meta"], promoTimer = meta["displayDuration"] as? Double {
            newPromo.timer = promoTimer
          }
        
          self.mediaObjects.insert(newPromo)
          self.featuredPromotionId = promoId
          NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: OddConstants.OddFeaturedPromotionLoadedNotification, object: self ) )
        }
    } else {
      self.featuredPromotionId = nil
    }
  }
  
  
  /// Builds the related `OddMediaObjects` for the current view.
  /// Related objects are stored in `mediaStore` for access
  ///
  /// Upon completion, an OddIncludedMediaItemsLoadedNotification is posted
  ///
  /// - parameter json: `jsonObject` a `jsonObject` containing the data to be parsed
  func buildIncludedMediaObjects(json: Array<jsonObject>) {

    json.forEach { (includedMediaObject) -> () in
      buildObjectFromJson(includedMediaObject)
    }
    NSNotificationCenter.defaultCenter().postNotification( NSNotification(name: OddConstants.OddIncludedMediaItemsLoadedNotification, object: self) )
  }
  
  #if os(iOS)
  /// Builds the `OddMediaObjects` included in the view for use
  /// by the `OddMenu`
  ///
  /// Note: A work in progress. Needs additional server side support.
  /// Server needs to provide these as specific types in order to 
  /// add support for this in our `objectFromJson()` method
  /// Currently only suppored for iOS apps. No tvOS support
  func buildIncludedMenuMediaObjects(json: Array<jsonObject>) {
    self.eventIds = Array()
    self.articleIds = Array()
    self.menuItemIds = Array()
    self.externalIds = Array()
    
    json.forEach { (includedMediaObject) -> () in
      OddLogger.info("BUILD MENU OBJECT")
      buildObjectFromJson(includedMediaObject)
    }
    
    OddLogger.info("Built \(self.eventIds?.count) events")
    OddLogger.info("Built \(self.articleIds?.count) articles")
    OddLogger.info("Built \(self.menuItemIds?.count) Menu Items")
    OddLogger.info("Built \(self.externalIds?.count) externals")
  }
  #endif
  
  //MARK: Menu
  #if os(iOS)
  // this will be moved to menuItem.swift once menu is in the API data
  func buildDefaultMenu(callback: (Bool) -> () ) {
    self.homeMenu = OddMenu()
    let search = OddMenuItem(title: "Search", type: .Search, objectId: nil)
    let home = OddMenuItem(title: "Home", type: .Home, objectId: nil)
    
    let links = OddMenuItemCollection(title: nil, menuItems: [ search, home ])
    self.homeMenu.menuItemCollections.append(links)
    callback(true)
  }
  
  /// Builds the `OddMenu` for the current view
  ///
  /// - parameter json: `jsonObject` a `jsonObject` containing the data to be parsed
  /// - parameter callback: `(Bool) -> Void` a `jsonObject` a closure to be executed upon completion of the menu
  /// build. Returns true if the menu was built successfully
  ///
  /// Note: A work in progress. Needs additional server side support
  /// Currently only suppored for iOS apps. No tvOS support
  func buildMenu(json: jsonObject, callback: (Bool) -> Void ) {
    if let included = self.included {
      buildIncludedMenuMediaObjects(included)
    }
    
    
    //USED
    if let relationships = json["relationships"] as? jsonObject, items = relationships["items"] as? jsonObject, data = items["data"] as? Array<jsonObject> {
      for item in data {
        if let id = item["id"] as? String {
          self.menuItemIds?.append(id)
        }
      }
    }
    
    
    //OLD CODE
    self.homeMenu = OddMenu()
    buildMenuItems(json)

    let search = OddMenuItem(title: "Search", type: .Search, objectId: nil)
    let home = OddMenuItem(title: "Home", type: .Home, objectId: nil)
    var menuItems: Array<OddMenuItem> = [ search, home ]
    
    menuItems += buildMenuItems(json)
    
    let links = OddMenuItemCollection(title: nil, menuItems: menuItems)
    self.homeMenu.menuItemCollections.append(links)
    
    callback(true)
  }
  
  /// Builds the individual `OddMenuItems` in the json for an `OddMenuItemCollection`
  /// - parameter json: `jsonObject` a `jsonObject` containing the data to be parsed
  /// - returns: An `Array` of `OddMenuItems.` May be empty
  ///
  /// Note: A work in progress. Needs additional server side support
  /// Currently only suppored for iOS apps. No tvOS support
  func buildMenuItems(json: jsonObject) -> Array<OddMenuItem> {
    var itemArray: Array<OddMenuItem> = []
    if let relationships = json["relationships"] as? jsonObject, items = relationships["items"] as? jsonObject, data = items["data"] as? Array<jsonObject> {
      for item in data {
        if let id = item["id"] as? String, type = item["type"] as? String {
          //NO, need to search included
          if type != "view" {
            if let object = self.findJsonObjectOfType(type, id: id) {
              var newItem = OddMenuItem()
              newItem.menuItemFromJson(object)
              itemArray.append(newItem)
            }
          }
        }
      }
    }
    return itemArray
  }
  #endif
  
  /// Builds an `OddMediaObject` of a type specified in the provided `jsonObject`
  ///
  /// This method differs from `buildObjectFromJson()` in that this method returns the
  /// object created and the type.
  ///
  /// - parameter json: `jsonObject` a `jsonObject` containing the data to be parsed
  /// - returns: A `Tuple` containing the `OddMediaObject.` and the type. 
  /// May return (nil, nil) if unsuccessful
  ///
  /// Note: Currently only builds `OddVideo` and `OddMediaObjectCollection` objects
  /// 
  /// See also: `buildObjectFromJson( json: jsonObject )`
  func objectFromJson( json: jsonObject ) -> ( object: OddMediaObject?, type: OddMediaObjectType? ) {
    var mediaObject: AnyObject?
  
    guard let type = json["type"] as? String,
      let mediaObjectType = OddMediaObjectType.fromString(type) else { return (nil, nil) }
    
      switch mediaObjectType {
      case .LiveStream, .Video:
        mediaObject = OddVideo.videoFromJson(json)
      case .Collection :
        mediaObject = OddMediaObjectCollection.mediaCollectionFromJson( json )
      default :
        break
      }
    
    if let mediaObject = mediaObject as? OddMediaObject {
      if mediaObject.cacheTime == nil {
        if let response = self.responseData,
          globalCacheTime = response["cacheTime"] as? Int {
            mediaObject.cacheTime = globalCacheTime
        }
      }
  
      return ( mediaObject, mediaObjectType )
    } else {
      return ( nil, nil )
    }

    
  }
  
  /// Builds an `OddMediaObject` of a type specified in the provided `jsonObject`
  /// The object created is inserted into `mediaObjects`
  ///
  /// This method differs from `objectFromJson()` in that this method does not return the
  /// object created.
  ///
  /// - parameter json: `jsonObject` a `jsonObject` containing the data to be parsed
  ///
  /// See also: `objectFromJson( json: jsonObject ) -> ( object: AnyObject?, type: String? )`
  func buildObjectFromJson( json: jsonObject ) {
    if let type = json["type"] as? String {
//      guard let mediaObjectType = OddMediaObjectType(rawValue: type) else { return }
      guard let mediaObjectType = OddMediaObjectType.fromString(type) else { return }
      
      var mediaObject: OddMediaObject?
      
      #if os(tvOS)
        switch mediaObjectType {
        case .Video, .LiveStream :
          mediaObject = OddVideo.videoFromJson(json)
        case .Promotion :
          mediaObject = OddPromotion.promotionFromJson(json)
        case .Collection :
          mediaObject = OddMediaObjectCollection.mediaCollectionFromJson(json)
        }
      #else
      switch mediaObjectType {
      case .Video, .LiveStream :
        mediaObject = OddVideo.videoFromJson(json)
      case .Promotion :
        mediaObject = OddPromotion.promotionFromJson(json)
      case .Collection :
        mediaObject = OddMediaObjectCollection.mediaCollectionFromJson(json)
      case .Article :
        mediaObject = OddArticle.articleFromJson( json )
      case .Event :
        mediaObject = OddEvent.eventFromJson( json)
      case .External :
        mediaObject = OddExternal.externalFromJson( json)
      }
      #endif
      
      if let mediaObject = mediaObject {
        if mediaObject.cacheTime == nil {
          if let response = self.responseData,
            globalCacheTime = response["cacheTime"] as? Int {
              mediaObject.cacheTime = globalCacheTime
          }
        }
        self.mediaObjects.insert(mediaObject)
      }
      
      
    }
    
    
  }
  
  /// Returns the portion of the `included` `jsonObject` that refers
  /// to the media obejct of `type` with a specified `id`
  ///
  /// - parameter type: String the type of media object to find. 
  /// Must match the type string as provided by the Odd API
  /// - parameter id: The id of the item to find
  ///
  /// - returns: jsonObject? The media object found or nil if none is found
  func findJsonObjectOfType(type: String, id: String) -> jsonObject? {
    if let included = self.included {
      for include: jsonObject in included {
        if let type = include["type"] as? String,
          anId = include["id"] as? String {
            if type == type && anId == id {
              return include
            }
        }
      }
    }
    return nil
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
  public func objectsOfType( type: OddMediaObjectType, ids : Array<String>, callback: (Array<OddMediaObject>) ->Void )  {
    
    if self.mediaObjects.isEmpty {
      fetchObjectsOfType(type, ids: ids, callback: { (objects) -> () in
        callback(objects)
      })
    } else {
      var objects: Array<OddMediaObject> = Array()
      var unMatchedIds: Array<String> = []
      
      for id: String in ids {
        var match = false
        // check store for existing videos
        for object in self.mediaObjects {
          if let objectId = object.id {
            if objectId == id && useCacheTTL && !object.cacheHasExpired {
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
      } // check store complete
      
      //fetch the batch of unmatched objects
      fetchObjectsOfType(type, ids: unMatchedIds, callback: { (fetchedObjects) -> () in
        fetchedObjects.forEach({ (obj) -> () in
          objects.append(obj)
        })
        callback(objects)
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
  public func fetchObjectType( type: OddMediaObjectType, id: String, callback: ( OddMediaObject? ) -> Void ) {
    API.get(nil , url: "\(type.toString() )s/\(id)") { (response, error) -> () in
      if error != nil {
        OddLogger.error("Error fetching \(type): \(id)")
        callback(nil)
      } else {
        if let json = response as? jsonObject,
          data = json["data"] as? jsonObject {
            switch type {
            case .Video:
              let video = OddVideo.videoFromJson(data)
              self.mediaObjects.insert(video)
              callback(video)
            case .Collection:
              let collection = OddMediaObjectCollection.mediaCollectionFromJson(data)
              self.mediaObjects.insert(collection)
              callback(collection)
            default:
              break
            } // switch
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
  public func fetchObjectsWithQuery ( type: OddMediaObjectType, query: String, callback: ( Array<OddMediaObject> ) -> () ) {
    API.get(nil, url: query) { (response, error) -> () in
      if error != nil {
        OddLogger.error("Error fetching objects with query")
        callback([])
      } else {
        guard let json = response as? jsonObject,
          data = json["data"] as? jsonArray else { callback([]); return }
        var mediaObjects: Array<OddMediaObject> = []
        for jsonObject in data {
          mediaObjects.append(type.toObject(jsonObject))
        }
        callback(mediaObjects)
      }
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
  public func fetchObjectsOfType ( type: OddMediaObjectType, ids: Array<String>, callback: ( Array<OddMediaObject> ) -> () ) {
    var responseArray: Array<OddMediaObject> = Array()
    
    if ids.isEmpty { callback(responseArray) }
    
    var callbackCount = 0
    for id : String in ids {
      fetchObjectType(type, id: id, callback: { (item) -> () in
        callbackCount += 1
        if item is OddVideo {
          if let foundVideo = item as? OddVideo {
            responseArray.append(foundVideo)
          }
        } else if item is OddMediaObjectCollection {
          if let foundCollection = item as? OddMediaObjectCollection {
            responseArray.append(foundCollection)
          }
        }
        if callbackCount == ids.count { callback(responseArray) }
      })
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
    
    if featuredMediaObject?.id == id { return featuredMediaObject }

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
    
    API.get( nil, url: "search?term=\(term)") { ( response, error ) -> () in
      if let _ = error {
        print("Error fetching search results")
        onResults (videos: nil, collections: nil)
      } else {
        if let json = response as? jsonObject {
          if let data = json["data"] as? Array<jsonObject> {
            var videoResults = Array<OddVideo>()
            var collectionResults = Array<OddMediaObjectCollection>()
            OddLogger.info("DATA: \(data)")
            OddLogger.info("\(data.count) results")
            for result: jsonObject in data {
              let resultObject = self.objectFromJson(result)
              
              switch resultObject.type {
              case .Some(.Video) :
                if let video = resultObject.object as? OddVideo {
                  self.mediaObjects.insert(video)
                  videoResults.append(video)
                }
              case .Some(.Collection) :
                if let collection = resultObject.object as? OddMediaObjectCollection {
                  self.mediaObjects.insert(collection)
                  collectionResults.append(collection)
                }
              default:
                break
              }
            }
            OddLogger.info("Found \(videoResults.count) videos and \(collectionResults.count)")
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