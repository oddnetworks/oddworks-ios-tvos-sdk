//
//  OddMediaObject.swift
//  PokerCentral
//
//  Created by Patrick McConnell on 9/9/15.
//  Copyright (c) 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

// have to use @objc here to get optional methods
/// Protocol for media objects to implement that helps with 
/// displaying their data in a `UITableviewcell`
@objc protocol DynamicMediaObject {
  /// The height of the tableviewcell when displaying
  /// the media objects information
  var cellHeight: CGFloat { get }
  
  /// The reuseIdentifier for the cell in the storyboard
  var cellReuseIdentifier: String { get }
  
  /// Method called by the `UITableViewController` to allow the media
  /// item to configure the cell accordingly
  ///
  /// - parameter cell: The cell to be configured. Cell will be of the 
  /// type set in `cellReuseIdentifier`
  func configureCell(cell: UITableViewCell)
  
  /// Optional method to allow the media item to initiate an action
  /// upon being selected from a table view.
  ///
  /// - parameter vc: The view controller that is the root of the 
  /// `UITableViewController` that contains the cell. Typically this
  /// is a UINavigationController. This is provided to allow the media
  /// item to push a new view controller on the stack if desired
  optional func performActionForSelection(vc: UIViewController)
}

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
  case Video
  case LiveStream
  case Collection
  case Promotion
  #if os(iOS)
  case Article
  case Event
  case External
  #endif
  static func fromString(str: String) -> OddMediaObjectType? {
    #if os(tvOS)
      switch str {
      case "video": return .Video
      case "liveStream": return .LiveStream
      case "collection": return .Collection
      case "promotion": return .Promotion
      default: return nil
      }
    #else
      switch str {
      case "video": return .Video
      case "liveStream": return .LiveStream
      case "collection": return .Collection
      case "promotion": return .Promotion
      case "article": return .Article
      case "event": return .Event
      case "external": return .External
      default: return nil
      }
    #endif
  }
  
  func toString() -> String {
    #if os(tvOS)
      switch self {
      case .Video: return "video"
      case .LiveStream: return "liveStream"
      case .Collection: return "collection"
      case .Promotion: return "promotion"
      }
    #else
      switch self {
      case .Video: return "video"
      case .LiveStream: return "liveStream"
      case .Collection: return "collection"
      case .Promotion: return "promotion"
      case .Article: return "article"
      case .Event: return "event"
      case .External: return "external"
      }
    #endif

  }
  
  func toObject(data: jsonObject) -> OddMediaObject {
    #if os(tvOS)
    switch self {
    case .Video: return OddVideo.videoFromJson(data)
    case .LiveStream: return OddVideo.videoFromJson(data)
    case .Collection: return OddMediaObjectCollection.mediaCollectionFromJson(data)
    case .Promotion: return OddPromotion.promotionFromJson(data)
    }
    #else
    switch self {
    case .Video: return OddVideo.videoFromJson(data)
    case .LiveStream: return OddVideo.videoFromJson(data)
    case .Collection: return OddMediaObjectCollection.mediaCollectionFromJson(data)
    case .Promotion: return OddPromotion.promotionFromJson(data)
    case .Article: return OddArticle.articleFromJson(data)
    case .Event: return OddEvent.eventFromJson(data)
    case .External: return OddExternal.externalFromJson(data)
    }
    #endif
  }
}

/// The root object class for all media object types
///
/// Provides instance variables for common fields
@objc public class OddMediaObject: NSObject, NSCoding, DynamicMediaObject {

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
  public var urlString: String?
  
  /// A URL string to load this media object via API
  public var link: String?
  
  /// A URL string to a thumbnail image to be used in conjunction with the media object
  public var thumbnailLink: String?
  
  /// The thumbnail image asset for the media object.
  ///
  /// Fetched as needed. No public access. Client applications should access
  /// the thumbnail image via the `thumbnail()` method
  var _thumbnail: UIImage?
  
  /// The date the content was released
  public var releaseDate: String? // convert to date object
  
  /// A placeholder string for the title
  public var defaultTitle = "OddNetworks Media Object"
  
  /// A placeholder string for the media objects notes
  public var defaultSubtitle = "Another media object from OddNetworks"
  
  /// A string denoting the type of object.
  ///
  /// Must be overwritten by subclasses
  var contentTypeString: String { return "media" }

  /// A string denoting the type of cell to use when displaying this objects information.
  ///
  /// Must be overwritten by subclasses
  var cellReuseIdentifier: String { return "cell" }
  
  /// When displaying this media objects info in a `UITableViewCell` use this height
  var cellHeight: CGFloat { return 30 }
  
  /// When displaying this media object in a `UITableView` use this text for the header
  /// if specified. Typically only used for `OddMediaObjectsCollection` types
  var headerText: String? = nil
  
  /// When displaying this media object in a `UITableView` use this height for the header
  /// if specified. Typically only used for `OddMediaObjectsCollection` types
  var headerHeight: CGFloat = 0
  
  /// Customer specific information
  /// A customer may require data that only their application can make
  /// use of. In these cases this information is passed along in json
  /// format under the meta tag. The individual fields of the meta 
  /// section are not accessible directly via this API. It is the
  /// application developers responsibitly to parse this additional
  /// data
  public var meta : Dictionary<String, AnyObject?>?
  
  /// How long to cache this object for. Based on 
  /// HTTP header data.
  public var cacheTime: Int? = nil
  
  /// When was this object last updated from the server
  public var lastUpdate: NSDate = NSDate()
  
  public var cacheHasExpired: Bool {
    get {
      guard let ttl = cacheTime else { return false }
      let expireTime = lastUpdate.dateByAddingTimeInterval( NSTimeInterval(ttl) )
      return expireTime.timeIntervalSinceNow.isSignMinus
    }
  }
  
  /// Given the json for the object type parses the data and sets the
  /// instance variables as appropriate
  ///
  /// - parameter json: A `jsonObject` containing the data for this media object
  public override init() {
    super.init()
  }
  
  public func encodeWithCoder(coder: NSCoder) {
    coder.encodeObject(self.id, forKey: "id")
    coder.encodeObject(self.title, forKey: "title")
    coder.encodeObject(self.notes, forKey: "notes")
    coder.encodeObject(self.assetId, forKey: "assetId")
    coder.encodeObject(self.thumbnailLink, forKey: "thumbnailLink")
    coder.encodeObject(self.urlString, forKey: "urlString")
    coder.encodeObject(self.duration, forKey: "duration")
    coder.encodeObject(self.subtitle, forKey: "subtitle")
  }
  
  // Method for saving Media Objects
  required convenience public init?(coder decoder: NSCoder) {
    self.init()
    self.id = decoder.decodeObjectForKey("id") as? String
    self.title = decoder.decodeObjectForKey("title") as? String
    self.notes = decoder.decodeObjectForKey("notes") as? String
    self.assetId = decoder.decodeObjectForKey("assetId") as? String
    self.thumbnailLink = decoder.decodeObjectForKey("thumbnailLink") as? String
    self.urlString = decoder.decodeObjectForKey("urlString") as? String
    self.duration = decoder.decodeObjectForKey("duration") as? Int
    self.subtitle = decoder.decodeObjectForKey("subtitle") as? String
  }
  
  
  
  func configureWithJson(json: jsonObject) {
    self.id = json["id"] as? String
    
    if let links = json["links"] as? jsonObject,
      selfLink = links["self"] as? String {
        self.link = selfLink
    }
    
    if let attribs = json["attributes"] as? jsonObject {
      self.contentRating = attribs["contentRating"] as? String
      self.notes = attribs["description"] as? String
      self.title = attribs["title"] as? String
      self.subtitle = attribs["subtitle"] as? String
      self.urlString = attribs["url"] as? String
      self.duration = attribs["duration"] as? Int
      self.releaseDate = attribs["releaseDate"] as? String
      if let images = attribs["images"] as? jsonObject {
        self.thumbnailLink = images["aspect16x9"] as? String
      }
      if let ads = attribs["ads"] as? jsonObject, id = ads["assetId"] as? String {
        self.assetId = id
      }
    }
    
    self.meta = json["meta"] as? jsonObject
    
    self.cacheTime = json["cacheTime"] as? Int
    self.lastUpdate = NSDate()
  }
  
  /// Helper method to return the media objects duration as an `NSTimeInterval`
  ///
  /// returns: An `NSTimeInterval` representation of the objects duration
  func durationAsTimeInterval() -> NSTimeInterval {
    var interval : Double = 0
    if self.duration != nil {
      interval = NSTimeInterval(self.duration! / 1000)
    }
    return interval
  }
  
  
  /// Helper method to provide the media objects duration as a `String`
  ///
  /// returns: A `String` representation of the objects duration
  public func durationAsTimeString() -> String {
    var interval : Double = 0
    if self.duration != nil {
      interval = NSTimeInterval(self.duration! / 1000)
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
    public func thumbnail( callback: (UIImage?) -> Void  ) {
      if _thumbnail == nil {
  
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { [ weak self] in
  
          if let weakSelf = self {
            if let link = weakSelf.thumbnailLink {
              if let thumbnailURL = NSURL(string: link) {
                if let imgData = NSData(contentsOfURL: thumbnailURL) {
                  weakSelf._thumbnail = UIImage(data: imgData )
                  weakSelf._thumbnail?.accessibilityIdentifier = "placeholderId"
                }
    
                dispatch_async(dispatch_get_main_queue(), { [ weakSelf ] in
                  callback(weakSelf._thumbnail )
                })
  
              }
            }
          }
        }
      } else {
        callback(_thumbnail)
      }
    }

//  public func thumbnail( callback: (UIImage) -> Void  ) {
//    if _thumbnail == nil {
//      
//      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { [ weak self] in
//
//        if let weakSelf = self {
//          if let link = weakSelf.thumbnailLink {
//            if let thumbnailURL = NSURL(string: link) {
//              if let imgData = NSData(contentsOfURL: thumbnailURL) {
//                weakSelf._thumbnail = UIImage(data: imgData )
//                weakSelf._thumbnail?.accessibilityIdentifier = "placeholderId"
//              }
//              
//              // if thumbnail is still nil use our default
//              if weakSelf._thumbnail == nil {
//                weakSelf._thumbnail = UIImage(named: "oddworksDefaultThumbnail")
//              }
//              
//              dispatch_async(dispatch_get_main_queue(), { [ weakSelf ] in
//                callback(weakSelf._thumbnail! )
//              })
//              
//            }
//          }
//        }
//      }
//    } else {
//      callback(_thumbnail!)
//    }
//  }
  
  
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
  public func valueForMetaKey(key: String) -> AnyObject? {
    if let keys = metaKeys() {
      if keys.contains(key) {
        return self.meta![key]!
      }
    }
    return nil
  }
  
  
  //MARK: - Dynamic Media Object
  
  /// A method to configure a `UITableViewCell` when displaying the information
  /// for this media object.
  ///
  /// Subclasses should override to provide more specific information on their type
  ///
  /// - parameter cell: a `UITableViewCell` to be configured
  func configureCell(cell : UITableViewCell) {
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
  func viewForTableViewHeader(tableView: UITableView) -> UIView? {
    return nil
  }
  
  
}
