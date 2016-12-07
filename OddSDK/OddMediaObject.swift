//
//  OddMediaObject.swift
//
//
//  Created by Patrick McConnell on 9/9/15.
//  Copyright (c) 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit


// have to use @objc here to get optional methods
/// Protocol for media objects to implement that helps with
/// displaying their data in a `UITableviewcell`
//@objc protocol DynamicMediaObject {
//  /// The height of the tableviewcell when displaying
//  /// the media objects information
//  var cellHeight: CGFloat { get }
//  
//  /// The reuseIdentifier for the cell in the storyboard
//  var cellReuseIdentifier: String { get }
//  
//  /// Method called by the `UITableViewController` to allow the media
//  /// item to configure the cell accordingly
//  ///
//  /// - parameter cell: The cell to be configured. Cell will be of the
//  /// type set in `cellReuseIdentifier`
//  func configureCell(cell: UITableViewCell)
//  
//  /// Optional method to allow the media item to initiate an action
//  /// upon being selected from a table view.
//  ///
//  /// - parameter vc: The view controller that is the root of the
//  /// `UITableViewController` that contains the cell. Typically this
//  /// is a UINavigationController. This is provided to allow the media
//  /// item to push a new view controller on the stack if desired
//  optional func performActionForSelection(vc: UIViewController)
//}

/// The known types of `OddMediaObject`s
///
// The string values are the names they are know as to the API server
//public enum OddMediaObjectType: String {
//  case Video      = "video"
//  case LiveStream = "liveStream"
//  case Collection = "collection"
//  case Promotion  = "promotion"
//  case Article    = "article"
//  case Event      = "event"
//  case External   = "external"
//}

// while we would prefer this was a string type
// for interoperability with ObjC this must be
// an Int type with a helper to convert from string
@objc public enum OddMediaObjectType: Int {
  case view
  case video
  case liveStream
  case collection
  case promotion
  #if os(iOS)
  case article
  case event
  case external
  #endif
  
  static func fromString(_ str: String) -> OddMediaObjectType? {
    #if os(tvOS)
      switch str {
      case "view": return .view
      case "video": return .video
      case "liveStream": return .liveStream
      case "collection": return .collection
      case "promotion": return .promotion
      default: return nil
      }
    #else
      switch str {
      case "view": return .view
      case "video": return .video
      case "liveStream": return .liveStream
      case "collection": return .collection
      case "promotion": return .promotion
      case "article": return .article
      case "event": return .event
      case "external": return .external
      default: return nil
      }
    #endif
  }
  
  func toString() -> String {
    #if os(tvOS)
      switch self {
      case .view: return "view"
      case .video: return "video"
      case .liveStream: return "liveStream"
      case .collection: return "collection"
      case .promotion: return "promotion"
      }
    #else
      switch self {
      case .view: return "view"
      case .video: return "video"
      case .liveStream: return "liveStream"
      case .collection: return "collection"
      case .promotion: return "promotion"
      case .article: return "article"
      case .event: return "event"
      case .external: return "external"
      }
    #endif
    
  }
  
  func toObject(_ data: jsonObject) -> OddMediaObject {
    #if os(tvOS)
      switch self {
      case .view: return OddView.viewFromJson(data)
      case .video: return OddVideo.videoFromJson(data)
      case .liveStream: return OddVideo.videoFromJson(data)
      case .collection: return OddMediaObjectCollection.mediaCollectionFromJson(data)
      case .promotion: return OddPromotion.promotionFromJson(data)
      }
    #else
      switch self {
      case .view: return OddView.viewFromJson(data)
      case .video: return OddVideo.videoFromJson(data)
      case .liveStream: return OddVideo.videoFromJson(data)
      case .collection: return OddMediaObjectCollection.mediaCollectionFromJson(data)
      case .promotion: return OddPromotion.promotionFromJson(data)
      case .article: return OddArticle.articleFromJson(data)
      case .event: return OddEvent.eventFromJson(data)
      case .external: return OddExternal.externalFromJson(data)
      }
    #endif
  }
}

/// The root object class for all media object types
///
/// Provides instance variables for common fields
@objc public class OddMediaObject: NSObject, NSCoding {
  
  /// The id of the media object in the database
  public var id: String?
  
  /// The id of the `OddMediaObject` to report to certain advertising platforms
  public var assetId: String?
  
  /// Is the user able to access this content (i.e. authorization/entitlement)
  ///
  /// Note, content is publicly accessible by default. Client applications must
  /// implement methods to check for authorization and set accordingly
  public var accessible: Bool = true
  
  /// The content rating of the asset for parental control, etc
  public var contentRating: String?
  
  /// Information about the media object. This field is known as description on the server
  /// NSObject reserves the description keyword
  public var notes: String?
  
  /// The title of the media object
  public var title: String?
  
  /// The subtitle for the media object
  public var subtitle: String?
  
  /// The duration of the assets play time. Typically for `OddVideo` types
  public var duration: Int?
  
  /// The URL string to load the asset from the content provider
  public var urlString: String? {
    get {
//      guard let source = sources?[0] else { return nil }
      guard let sourceUrl = bestSourceURL()  else { return nil }
      return sourceUrl
    }
  }
  
  /// A URL string to load this media object via API
  public var link: String?
  
  /// FOR LEGACY APPS ONLY. Returns the first image in the image collection
  public var thumbnailLink: String? {
    return self.images?.first?.url
  }
  
  /// For Oddworks 2.0+ mediaObjects have an array of images
  public var images: Array<OddImage>?

  /// Oddworks 3.0+ has an array of url source objects
  public var sources: Array<OddSource>?
  
  /// A customizable URL string that enables formatting on the thumbnailLink
  public var formattedThumbnailLink: String?
  
  /// The thumbnail image asset for the media object.
  ///
  /// Fetched as needed. No public access. Client applications should access
  /// the thumbnail image via the `thumbnail()` method
  var _thumbnail: UIImage?
  
  /// The date the content was released
  public var releaseDate: String? // convert to date object
  
  /// The date the media object was downloaded to the device
  public var downloadDate: Date?
  
  /// A placeholder string for the title
  public var defaultTitle = "OddNetworks Media Object"
  
  /// A placeholder string for the media objects notes
  public var defaultSubtitle = "Another media object from OddNetworks"
  
  /// A string denoting the type of object.
  ///
  /// Must be overwritten by subclasses
  var contentTypeString: String { return "media" }
  
  var mediaObjectType: OddMediaObjectType? {
    get {
      return OddMediaObjectType.fromString(self.contentTypeString)
    }
  }
  
  /// A string denoting the type of cell to use when displaying this objects information.
  ///
  /// Must be overwritten by subclasses
//  var cellReuseIdentifier: String { return "cell" }
  
  /// When displaying this media objects info in a `UITableViewCell` use this height
//  var cellHeight: CGFloat { return 30 }
  
  /// When displaying this media object in a `UITableView` use this text for the header
  /// if specified. Typically only used for `OddMediaObjectsCollection` types
//  var headerText: String? = nil
  
  /// When displaying this media object in a `UITableView` use this height for the header
  /// if specified. Typically only used for `OddMediaObjectsCollection` types
//  var headerHeight: CGFloat = 0
  
  /// Customer specific information
  /// A customer may require data that only their application can make
  /// use of. In these cases this information is passed along in json
  /// format under the meta tag. The individual fields of the meta
  /// section are not accessible directly via this API. It is the
  /// application developers responsibitly to parse this additional
  /// data
  public var meta : jsonObject?
  
  /// How long to cache this object for. Based on
  /// HTTP header data.
  public var cacheTime: Int? = nil
  
  /// When was this object last updated from the server
  public var lastUpdate: Date = Date()
  
  public var cacheHasExpired: Bool {
    get {
      guard let ttl = cacheTime else { return false }
      let expireTime = lastUpdate.addingTimeInterval( TimeInterval(ttl) )
      return expireTime.timeIntervalSinceNow.sign == .plus
    }
  }
  
  var relationshipNodes: Dictionary<String, OddRelationshipNode> = [:]
  
  /// Given the json for the object type parses the data and sets the
  /// instance variables as appropriate
  ///
  /// - parameter json: A `jsonObject` containing the data for this media object
  public override init() {
    super.init()
  }
  
  public func encode(with coder: NSCoder) {
    coder.encode(self.id, forKey: "id")
    coder.encode(self.title, forKey: "title")
    coder.encode(self.notes, forKey: "notes")
    coder.encode(self.assetId, forKey: "assetId")
//    coder.encodeObject(self.thumbnailLink, forKey: "thumbnailLink")
    coder.encode(self.urlString, forKey: "urlString")
    coder.encode(self.duration, forKey: "duration")
    coder.encode(self.subtitle, forKey: "subtitle")
    coder.encode(self.downloadDate, forKey: "downloadDate")
  }
  
  // Method for saving Media Objects
  required convenience public init?(coder decoder: NSCoder) {
    self.init()
    self.id = decoder.decodeObject(forKey: "id") as? String
    self.title = decoder.decodeObject(forKey: "title") as? String
    self.notes = decoder.decodeObject(forKey: "notes") as? String
    self.assetId = decoder.decodeObject(forKey: "assetId") as? String
//    self.thumbnailLink = decoder.decodeObjectForKey("thumbnailLink") as? String
//    self.urlString = decoder.decodeObject(forKey: "urlString") as? String
    self.duration = decoder.decodeObject(forKey: "duration") as? Int
    self.subtitle = decoder.decodeObject(forKey: "subtitle") as? String
    self.downloadDate = decoder.decodeObject(forKey: "downloadDate") as? Date
  }
  
  
  
  func configureWithJson(_ json: jsonObject) {
    self.id = json["id"] as? String
    if let links = json["links"] as? jsonObject,
      let selfLink = links["self"] as? String {
        self.link = selfLink
    }
    
    if let attribs = json["attributes"] as? jsonObject {
      self.contentRating = attribs["contentRating"] as? String
      self.notes = attribs["description"] as? String
      self.title = attribs["title"] as? String
      self.subtitle = attribs["subtitle"] as? String
//      self.urlString = attribs["url"] as? String
      self.duration = attribs["duration"] as? Int
      self.releaseDate = attribs["releaseDate"] as? String
//      if let images = attribs["images"] as? jsonObject {
//        self.thumbnailLink = images["aspect16x9"] as? String
//      }
      if let images = attribs["images"] as? jsonArray {
        self.images = []
        images.forEach({ (image) in
          if let newImage = OddImage.imageFromJson(image) {
            self.images?.append(newImage)
          }
        })
      }
      
      if let sources = attribs["sources"] as? jsonArray {
        self.sources = []
        sources.forEach({ (source) in
          if let newSource = OddSource.sourceFromJson(source) {
            self.sources?.append(newSource)
          }
        })
      }

      if let ads = attribs["ads"] as? jsonObject, let id = ads["assetId"] as? String {
        self.assetId = id
      }
    }
    
    // relationships
    if let related = json["relationships"] as? jsonObject {
      for (key, value) in related {
        guard let value = value as? jsonObject else { return }
        
        if let data = value["data"] as? jsonObject,
            let id = data["id"] as? String,
            let type = data["type"] as? String,
            let kind = OddMediaObjectType.fromString( type ) {
          let newRelationship = OddRelationship(id: id, mediaObjectType: kind)
          let newNode = OddRelationshipNode(single: newRelationship, multiple: nil)
          self.relationshipNodes[key] = newNode
        } else if let data = value["data"] as? jsonArray {
          var relationships = Array<OddRelationship>()
          data.forEach({ (dict) in
            guard let id = dict["id"] as? String,
              let type = dict["type"] as? String,
              let kind = OddMediaObjectType.fromString(type) else { return }
            relationships.append(OddRelationship(id: id, mediaObjectType: kind))
          })
          let newNode = OddRelationshipNode(single: nil, multiple: relationships)
          self.relationshipNodes[key] = newNode
        }
      }
    }
    
    self.meta = json["meta"] as? jsonObject
    
    self.cacheTime = json["cacheTime"] as? Int
    self.lastUpdate = Date()
    
//    for (key, value) in self.relationShips {
//      print("\(key) - \(value.id): \(value.mediaObjectType.toString())")
//    }
  }
  
  /// Helper method to return the media objects duration as an `NSTimeInterval`
  ///
  /// returns: An `NSTimeInterval` representation of the objects duration
  func durationAsTimeInterval() -> TimeInterval {
    var interval : Double = 0
    if self.duration != nil {
      interval = TimeInterval(self.duration! / 1000)
    }
    return interval
  }
  
  
  /// Helper method to provide the media objects duration as a `String`
  ///
  /// returns: A `String` representation of the objects duration
  public func durationAsTimeString() -> String {
    var interval : Double = 0
    if self.duration != nil {
      interval = TimeInterval(self.duration! / 1000)
    }
    return interval.stringFromTimeInterval()
  }
  
  
  /// Loads the media objects thumbnail image asset
  ///
  /// Checks if the `_thumbnail` asset is already present returning it if so.
  ///
  /// If the asset is not already loaded the asset is fetched and upon success the
  /// callback closure is executed with the image as a parameter
  ///
  /// parameter callback: A closure taking a `UIImage` as a parameter to be executed when the image is loaded
  public func thumbnail(_ callback: @escaping (UIImage?) -> Void  ) {
    let storedThumbnail = getThumbnail()
    if let thumbnail = storedThumbnail {
      callback(thumbnail)
    } else {
      var path: String?
      // allows developer to override the thumbnail link with custom formatting
      if let thumbnailLink = thumbnailLink {
        path = thumbnailLink
      }
      if let formattedPath = self.formattedThumbnailLink {
        path = formattedPath
      }
      if let path = path {
        let request = NSMutableURLRequest(url: URL(string: path)!)
// some optimization of this may be possible by configuring the maximum number of connections
// for your session. Your mileage may vary. Uncomment the next 3 lines and comment line 340 out
// to adjust number of connections used per sesssion
//        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
//        config.HTTPMaximumConnectionsPerHost = 1
//        let session = NSURLSession(configuration: config)
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
                  self.setThumbnail(image)
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
  }
  
  /// Convenience method to retun all keys in the
  /// mediaObjects meta dictionary
  public func metaKeys() -> Set<String>? {
    var result = Set<String>()
    if let meta = meta {
      meta.keys.forEach({ (key) -> () in
        result.insert(key)
      })
      return result
    }
    return nil
  }
  
  /// Convenience method to return a given keys value
  /// or nil if it is not found
  public func valueForMetaKey(_ key: String) -> AnyObject? {
    if let keys = metaKeys() {
      if keys.contains(key) {
        return self.meta![key]!
      }
    }
    return nil
  }
  
  /// Convenience method to retun all keys in the
  /// mediaObjects meta dictionary
  public func relationshipNodeNames() -> Set<String>? {
    if self.relationshipNodes.count == 0 { return nil }
    
    var result = Set<String>()
    
    self.relationshipNodes.keys.forEach({ (key) -> () in
      result.insert(key)
    })
    return result
  }
  
  /// Convenience method to return a given keys value
  /// or nil if it is not found
  public func relationshipNodeWithName(_ name: String) -> OddRelationshipNode? {
    if let names = relationshipNodeNames() {
      if names.contains(name) {
        return self.relationshipNodes[name]!
      }
    }
    return nil
  }
  
  public func numberOfItemsInRelationshipNodeWithName(_ name: String) -> Int {
    guard let node = relationshipNodeWithName(name) else { return 0 }
    
    return node.numberOfRelationships
  }
  
  
  public func objectsForRelationship(withName name: String, _ callback: @escaping (_ objects: Array<OddMediaObject>, _ errors: Array<NSError>?) ->())  {
  
    guard let node = self.relationshipNodeWithName(name) else {
      let e = NSError(domain: "Odd", code: 111, userInfo: ["error": "No node found with name: \(name)"])
      callback(Array<OddMediaObject>(), [e])
      return
    }
    
    node.getAllObjects { (objects, errors) in
      callback(objects, errors)
    }
  }
  //MARK: - Dynamic Media Object
  
  /// A method to configure a `UITableViewCell` when displaying the information
  /// for this media object.
  ///
  /// Subclasses should override to provide more specific information on their type
  ///
  /// - parameter cell: a `UITableViewCell` to be configured
  func configureCell(_ cell : UITableViewCell) {
    cell.textLabel?.text = self.title
    cell.detailTextLabel?.text = self.notes
  }
  
  /// A method to provide a `UIView` to be used for a header when displayed
  /// in a `UITableView`
  ///
  /// Note: This default implementation provides no view (nil). This
  /// method is typically only used for `OddMediaObjectsCollection` types
  ///
  /// - parameter tableView: The `UITableView` that will display the header
  ///
  /// - returns: An optional `UIView` to be used as the header view
  func viewForTableViewHeader(_ tableView: UITableView) -> UIView? {
    return nil
  }
  
  func setThumbnail(_ image: UIImage) {
    if let url = self.thumbnailLink {
      OddContentStore.sharedStore.imageCache.setObject(image, forKey: url as NSString)
    }
  }
  
  func getThumbnail() -> UIImage? {
    if let url = self.thumbnailLink {
      return OddContentStore.sharedStore.imageCache.object(forKey: url as NSString)
    }
    return nil
  }
  
  public func objectIsOfType(_ type: OddMediaObjectType) -> Bool {
    var result = false
    switch type {
    case .view: result = self is OddView
    case .video: result = self is OddVideo
    case .collection: result = self is OddMediaObjectCollection
    case .promotion: result = self is OddPromotion
    default: break
    }
    return result
  }
  
  public func addToWatchList(onResult: @escaping ( _ success: Bool, _ error: NSError? ) -> Void) -> Void {
    if self.contentTypeString == "video" || self.contentTypeString == "collection" {
      
      guard let theId = self.id,
        let objectType = OddMediaObjectType.fromString(self.contentTypeString) else {
          let error = OddContentStore.sharedStore.buildError("Incorrect Media Object data", errorCode: 115, notification: nil)
          onResult(false, error)
          return
      }
      
      let params = [
        "data": [
          "id": theId,
          "type": self.contentTypeString
        ]
      ]
      
      OddContentStore.sharedStore.API.post(params as [String : AnyObject]?, url: "viewers/\(OddViewer.current.id)/relationships/watchlist", altDomain: nil) { (response, error) -> () in
        if error != nil {
          let error = OddContentStore.sharedStore.buildError("Error adding item to watchlist", errorCode: 112, notification: nil)
          onResult(false, error)
        } else {
          if response?.statusCode == 202 {
            let watchItem = OddRelationship(id: theId, mediaObjectType: objectType)
            OddViewer.current.watchlist.insert(watchItem)
            NotificationCenter.default.post(Notification(name: OddConstants.OddWatchlistUpdated , object: nil))
            onResult(true, nil)
          } else {
            let error = OddContentStore.sharedStore.buildError("Incorrect server response for add to watchlist", errorCode: 114, notification: nil)
            onResult(false, error)
          }
        }
      }
    } else {
      let error = OddContentStore.sharedStore.buildError("Watchlist does not support object type", errorCode: 116, notification: nil)
      onResult(false, error)
    }
  }

  
  public func removeFromWatchList(onResult: @escaping ( _ success: Bool, _ error: NSError? ) -> Void) -> Void {
    if self.contentTypeString == "video" || self.contentTypeString == "collection" {
      
      guard let theId = self.id,
        let objectType = OddMediaObjectType.fromString(self.contentTypeString) else {
          let error = OddContentStore.sharedStore.buildError("Incorrect Media Object data", errorCode: 115, notification: nil)
          onResult(false, error)
          return
      }
      
      let params = [
        "data": [
          "id": theId,
          "type": self.contentTypeString
        ]
      ]
      
      OddContentStore.sharedStore.API.delete(params as [String : AnyObject]?, url: "viewers/\(OddViewer.current.id)/relationships/watchlist") { (response, error) -> () in
        if error != nil {
          let error = OddContentStore.sharedStore.buildError("Error removing item from watchlist", errorCode: 117, notification: nil)
          onResult(false, error)
        } else {
          if response?.statusCode == 202 {
            let watchItem = OddRelationship(id: theId, mediaObjectType: objectType)
            OddViewer.current.watchlist.remove(watchItem)
            NotificationCenter.default.post(Notification(name: OddConstants.OddWatchlistUpdated , object: nil))
            onResult(true, nil)
          } else {
            let error = OddContentStore.sharedStore.buildError("Incorrect server response for remove from watchlist", errorCode: 118, notification: nil)
            onResult(false, error)
          }
        }
      }
    } else {
      let error = OddContentStore.sharedStore.buildError("Watchlist does not support object type", errorCode: 119, notification: nil)
      onResult(false, error)
    }
  }
  
  func bestSourceURL() -> String? {
    
    func bestBitrateSource(fromSources sources: [OddSource]) -> OddSource? {
      if sources.isEmpty { return nil }
      var highest = -1
      var result = sources.first
      sources.forEach({ (source) in
        if source.maxBitrate != nil {
          if source.maxBitrate! > highest {
            highest = source.maxBitrate!
            result = source
          }
        } else {
          OddLogger.error("No maxBitrate on MediaObject")
        }
      })
      
      return result
    }
    
    guard let sources = self.sources else { return nil }
    
    if sources.count == 1 {
      guard let source = sources.first else { return nil }
        let url = source.url
      return url
    }
    
    let hlsSources = sources.filter {$0.container?.uppercased() == "M2TS"}
    let mp4Sources = sources.filter {$0.container?.uppercased() == "MP4"}
    
    if !hlsSources.isEmpty {
      guard let result = bestBitrateSource(fromSources: hlsSources) else { return nil }
      return result.url
    } else if !mp4Sources.isEmpty {
      guard let result = bestBitrateSource(fromSources: mp4Sources) else { return nil }
      return result.url
    }
    return nil
  }
  
  
}
