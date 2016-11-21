//
//  OddVideo.swift
//
//
//  Created by Patrick McConnell on 7/31/15.
//  Copyright (c) 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

/// An `OddMediaObject` subclass representing a video asset
@objc public class OddVideo: OddMediaObject {
  
  /// Read only variable to provide the asset type
  override public var contentTypeString: String { return "video" }
  
  /// `UITableViewCell` type to be used when displaying video assets
//  override var cellReuseIdentifier: String { return "VideoInfoCell" }
  
  /// `UITableViewCell` height to be used when displaying video assets
//  override var cellHeight: CGFloat { return 80 }
  
  /// The type of player service used to play the video asset
  ///
  /// Videos can be played with various player types. The default is the 
  /// native AVPlayer. Client applications must implement their own support
  /// for other player types. See sample application support for Ooyala and web
  /// based players
  /// 
  /// This value will be set by the API and should only be read by client apps
  public var playerType: String? { get { return _playerType } }
  
  
  /// The private backing for playerType to enable readonly access
  /// for the public var
  var _playerType: String?
  
  /// Used by Ooyala based video players
  public var pCode: String?
  
  /// Used by Ooyala based video players
  public var embedCode: String?
  
  /// Used by Ooyala based video players
  public var domain: String?
  
  /// Used by web based video players
  public var playerUrlString: String?

  /// The URL for the videos closed captioning track if
  /// provided as a separate asset
  public var closedCaptionsUrlString: String?
  
  // The play progress for the current viewer
  public var position: Int?
  
  public var complete: Bool?
  
  public var shareText: String?
  public var sharingEnabled: Bool?
  
  /// Configures an `OddVideo` from a json object
  ///
  /// - parameter json: A `jsonObject` containing information pertaining to the video asset
  ///
  /// - returns: A configured `OddVideo`
  class func videoFromJson(_ json: jsonObject) -> OddVideo {
    let newVideo = OddVideo()
    newVideo.configureWithJson(json)

    newVideo.defaultTitle = "A Video"
    newVideo.defaultSubtitle = "Another fine video from Odd Networks"

    return newVideo
  }
  
  /// Helper method to build the object from json data
  ///
  /// - parameter json: A `jsonObject` containing information pertaining to the video asset
  ///
  /// Note: Should not be called directly. Doing so may result in an object not
  /// fully configured
  override func configureWithJson(_ json: jsonObject) {
    super.configureWithJson(json)
    addAdditionalMetaData(json)
  }

  
  /// Helper method to build the object from json data
  ///
  /// - parameter json: A `jsonObject` containing information pertaining to the video asset
  ///
  /// Note: Should not be called directly. Doing so may result in an object not
  /// fully configured
  func addAdditionalMetaData(_ json: jsonObject) {
    if let attributes = json["attributes"] as? jsonObject {
      self.position = attributes["position"] as? Int
      self.complete = attributes["complete"] as? Bool
        if let player = attributes["player"] as? jsonObject {
          self._playerType = player["type"] as? String
          self.pCode = player["pCode"] as? String
          self.embedCode = player["embedCode"] as? String
          self.domain = player["domain"] as? String
          self.playerUrlString = player["url"] as? String
          
          self.closedCaptionsUrlString = attributes["closedCaptions"] as? String
      }
      if let sharing = attributes["sharing"] as? jsonObject {
        self.sharingEnabled = sharing["enabled"] as? Bool
        self.shareText = sharing["text"] as? String
      }
    }
  }
  
  public func postPlayPosition(_ position: Int = 0, complete: Bool = false, onResult: @escaping ( _ success: Bool, _ error: NSError? ) -> Void) -> Void {
    guard let theId = self.id else {
        let error = OddContentStore.sharedStore.buildError("Incorrect Media Object data", errorCode: 120, notification: nil)
        onResult(false, error)
        return
    }
    
    let params = [
      "data": [
        "type": "progress",
        "attributes": [
          "position": position,
          "complete": complete
        ]
      ]
    ]
    
    OddContentStore.sharedStore.API.post(params as [String : AnyObject]?, url: "videos/\(theId)/progress", altDomain: nil) { (response, error) -> () in
      if error != nil {
        let error = OddContentStore.sharedStore.buildError("Error posting video play progress", errorCode: 112, notification: nil)
        onResult(false, error)
      } else {
        if response?.statusCode == 201 {
          self.position = position
          self.complete = complete
          
          //OddContentStore.sharedStore.mediaObjects.remove(self)
          onResult(true, nil)
        } else {
          let error = OddContentStore.sharedStore.buildError("Incorrect server response for post video progress", errorCode: 121, notification: nil)
          onResult(false, error)
        }
      }
    }

  }
}
