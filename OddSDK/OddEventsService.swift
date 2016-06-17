//
//  OddEventsService.swift
//  OddSDK
//
//  Created by Patrick McConnell on 6/15/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import UIKit

public struct OddMediaPlayerInfo {
  var playerType: String?
  var elapsed: Int?
  var duration: Int?
  var videoSessionId: String?
  var errorMessage: String?
}

enum OddMetricAction: String {
  case AppInit      = "appInit"
  case ViewLoad     = "viewLoad"
  case VideoLoad    = "videoLoad"
  case VideoPlay    = "videoPlay"
  case VideoError   = "videoError"
  case VideoPlaying = "videoPlaying"
  case VideoStop    = "videoStop"
  case UserNew      = "userNew"
  
  // case AdRequest
  // case AdPlay  
}

@objc public class OddEventsService: NSObject {

  static public let defaultService = OddEventsService()
  
  var deliveryService: OddHTTPRequestService = APIService.sharedService
  var eventsURL: String { return "http://127.0.0.1:8888/" }
  
  private var _sessionId: String = ""
  public var videoSessionId: String = ""
  
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
    if self._sessionId.isEmpty {
      self._sessionId = NSUUID().UUIDString
    }
    return _sessionId
  }
  
  /// Generates a new UUID to be associated with a video session.
  ///
  /// The VideoSessionID is provided with every video event posting. It is used to group events by an
  /// instance of the media player working with a specific video asset.
  ///
  /// A new UUID should be generated upon Video:Load
  ///
  func resetVideoSessionId() {
    self.videoSessionId = NSUUID().UUIDString
  }
  
  public func postAppInitMetric(callback: APICallback? = nil) {
    postMetricForAction(.AppInit, playerInfo: nil, content: nil, callback: callback)
  }
  
  func postMetricForAction(action: OddMetricAction, playerInfo: OddMediaPlayerInfo?, content: OddMediaObject?, callback: APICallback?) {
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
          "action" : "\(stat.actionString)",
          "userId" : self.userId(),
          "sessionId" : self.sessionId()
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
          elapsed = beacon.elapsed,
          videoSessionId = beacon.videoSessionId {
          if var attributes = params["attributes"] as? jsonObject {
            attributes["elapsed"] = elapsed
            attributes["duration"] = "null"
            attributes["player"] = player
            attributes["videoSessionId"] = videoSessionId
            params["attributes"] = attributes
          }
          
          //need to have separate in case it is a live stream, in which case duration will not exist
          if let duration = beacon.duration {
            if var attributes = params["attributes"] as? jsonObject {
              attributes["duration"] = duration
              params["attributes"] = attributes
            }
          }
          
          // error message is optional and only added to video:error events
          if let errorMessage = beacon.errorMessage {
            if var attributes = params["attributes"] as? jsonObject {
              attributes["errorMessage"] = errorMessage
              params["attributes"] = attributes
            }
          }
        }
      }
      
      OddLogger.info("PARAMS SENT IN METRIC POST: \(params)")
      
      self.deliveryService.post(params, url: "events", altDomain: eventsURL) { (response, error) -> () in
        if let e = error {
          OddLogger.error("<<Metric post with type '\(stat.actionString)' failed with error: \(e.localizedDescription)>>")
          callback?(nil, error)
        } else {
          OddLogger.info("<<Metric Post Successful: '\(stat.actionString)'>>")
          callback?(params, nil)
        }
      }
    }
  }

  
}
