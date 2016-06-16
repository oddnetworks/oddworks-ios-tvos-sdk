//
//  OddEventsService.swift
//  OddSDK
//
//  Created by Patrick McConnell on 6/15/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import UIKit

@objc public class OddEventsService: NSObject {

  static public let defaultService = OddEventsService()
  private var _sessionId: String = ""
  
  override init() {
    super.init()
    let userId = self.userId()

    OddLogger.info("OddEventsService initialized with UserId: \( userId ) and SessionId: \( sessionId() )")
  }
  
  /// Provides the UUID associated with this device. 
  ///
  /// The userID is provided with every event posting. It is used to group events by the
  /// user identified with this device. At such a time as authorization is added the userId
  /// may be linked to an actual user
  ///
  /// This UUID is only generated once per app installation.
  ///
  /// -returns: A UUID in string format
  func userId() -> String {
    var userId = NSUserDefaults.standardUserDefaults().stringForKey(OddConstants.kUserIdKey)
    
    if userId == nil {
      userId = NSUUID().UUIDString
      NSUserDefaults.standardUserDefaults().setValue(userId, forKey: OddConstants.kUserIdKey)
    }
    
    return userId!
  }
  
  /// Provides the UUID associated with this app session.
  ///
  /// The sessionID is provided with every event posting. It is used to group events by an
  /// instance of the app running.
  ///
  /// This UUID is generated fresh each time the app is launched.
  ///
  /// -returns: A UUID in string format
  func sessionId() -> String {
    var token: dispatch_once_t = 0
    dispatch_once(&token) { () -> Void in
      self._sessionId = NSUUID().UUIDString
    }
    print("RETURNING: \(_sessionId)")
    return _sessionId
  }
  
  public func postAppInitMetric() {
    postMetricForAction(.AppInit, playerInfo: nil, content: nil)
  }
  
  func postMetricForAction(action: OddMetricAction, playerInfo: OddMediaPlayerInfo?, content: OddMediaObject?) {
    if let stat = OddContentStore.sharedStore.config?.analyticsManager.findEnabled(action) {
      //parsing content
      var contentId: String?
      var contentType: String?
      var contentTitle: String?
      var contentThumbnailURL: String?
      //      let organizationID = OddContentStore.sharedStore.organizationId
      
      if let content = content {
        contentId = content.id
        contentType = content.contentTypeString
        contentTitle = content.title
        contentThumbnailURL = content.thumbnailLink
      } else {
        contentId = "null"
        contentType = "null"
      }
      
      var params = [
        "type" : "event",
        "attributes" : [
          //   "organizationId" : "\(organizationID)",
          "action" : "\(stat.actionString)"
        ]
      ]
      
      if contentType != "null" {
        if var attributes = params["attributes"] as? jsonObject {
          attributes["contentType"] = "\(contentType!)"
          attributes["contentId"] = "\(contentId!)"
          attributes["contentTitle"] = "\(contentTitle!)"
          attributes["contentThumbnailURL"] = "\(contentThumbnailURL!)"
          params["attributes"] = attributes
        }
        
        if let beacon = playerInfo,
          player = beacon.playerType,
          elapsed = beacon.elapsed {
          if var attributes = params["attributes"] as? jsonObject {
            attributes["elapsed"] = elapsed
            attributes["duration"] = "null"
            attributes["player"] = player
            params["attributes"] = attributes
          }
          
          //need to have separate in case it is a live stream, in which case duration will not exist
          if let duration = beacon.duration {
            if var attributes = params["attributes"] as? jsonObject {
              attributes["duration"] = duration
              params["attributes"] = attributes
            }
          }
        }
      }
      
      OddLogger.info("PARAMS SENT IN METRIC POST: \(params)")
      
      APIService.sharedService.post(params, url: "events") { (response, error) -> () in
        if let e = error {
          OddLogger.error("<<Metric post with type '\(stat.actionString)' failed with error: \(e.localizedDescription)>>")
        } else {
          OddLogger.info("<<Metric Post Successful: '\(stat.actionString)'>>")
        }
      }
    }
  }

  
}
