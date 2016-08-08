//
//  OddMetricService.swift
//  Odd-iOS
//
//  Created by Matthew Barth on 10/2/15.
//  Copyright © 2015 Odd Networks, LLC. All rights reserved.
//

import Foundation
import CoreMedia

private let _defaultManager = OddMetricService()

//MARK: General Typealiases
enum OddMetricAction: String {
  case AppInit
  case ViewLoad
  case VideoPlay
  case VideoError
  case VideoPlaying
  case VideoStop
}

//enum PlayerType: String {
//  case Chromecast = "chromecast"
//  case Local      = "device"
//  case Airplay    = "airplay"
//}

// this will go away once metrics no longer require stuff they 
// already have on the server like playerType and duration
public struct OddMediaPlayerInfo {
  var playerType: String?
  var elapsed: Int?
  var duration: Int?
  
  public init(playerType: String?, elapsed: Int?, duration: Int?) {
    self.playerType = playerType
    self.elapsed = elapsed
    self.duration = duration
  }
}


/// A service class to post metric data to the Oddworks server.
/// Allows monitoring of application functions via Oddworks
public struct OddMetricService {
  
  // MARK: Public Vars/Methods
  
  /// The singleton instance of the OddMeticServer for the users application.
//  public class var defaultService: OddMetricService {
//    return _defaultManager
//  }
  
  
  /// Posts a metric when the app initializes. Client apps should not need to call this method.
  /// OddContentStore will post this metric when the application loads the config
  public static func postAppInitMetric() {
    OddMetricService.postMetricForAction(.AppInit, playerInfo: nil, content: nil)
  }
  
  
  /// Posts a metric when a given view is loaded in the app to display a media object
  /// Client apps may call this method in any way desired to mark the loading of views and objects
  ///
  /// Client apps should post this metric at times that make sense to the applications design
  public static func postViewLoadedWithMediaObject(_ mediaObject: OddMediaObject) {
    OddMetricService.postMetricForAction(.ViewLoad, playerInfo: nil, content: mediaObject)
  }
  
  /// Posts a metric when a media object begins playing in a media player. Clients will
  /// typically post this metric when a video begins playing.
  ///
  /// Client apps should post this metric at times that make sense to the applications design
  public static func postMediaPlayerStartedWithMediaObject(_ mediaObject: OddMediaObject) {
    OddMetricService.postMetricForAction(.VideoPlay, playerInfo: nil, content: mediaObject)
  }
  
  /// Posts a metric to indicate the elapsed time in the media player for a given media object. Typically posted
  /// at intervals to track the playing of media objects.
  ///
  /// Client apps should post this metric at times that make sense to the applications design
  public static func postMediaPlayerIsPlayingWithMediaObject(_ mediaObject: OddMediaObject, playerInfo: OddMediaPlayerInfo) {
    OddMetricService.postMetricForAction(.VideoPlaying, playerInfo: playerInfo, content: mediaObject)
  }
  
  /// Posts a metric when a media player stops playing a media object for any reason. Typically posted
  /// when a video ends or a user navigates away from a player view.
  ///
  /// Client apps should post this metric at times that make sense to the applications design
  public static func postMediaPlayerStopedPlayingMediaObject(_ mediaObject: OddMediaObject, playerInfo: OddMediaPlayerInfo) {
    OddMetricService.postMetricForAction(.VideoStop, playerInfo: playerInfo, content: mediaObject)
  }
  /// Posts a metic when a media player encounters an error. Client applicaitons will need to monitor
  /// their media players for notifications when errors occcur and post accordingly
  public static func postMediaPlayerDidEncounterErrorWithMediaObject(_ mediaObject: OddMediaObject, playerInfo: OddMediaPlayerInfo) {
    OddMetricService.postMetricForAction(.VideoError, playerInfo: playerInfo, content: mediaObject)
  }
  
  static func postMetricForAction(_ action: OddMetricAction, playerInfo: OddMediaPlayerInfo?, content: OddMediaObject?) {
    if let stat = OddContentStore.sharedStore.config?.analyticsManager.findEnabled(action) {
      //parsing content
      var contentId: String?
      var contentType: String?
//      let organizationID = OddContentStore.sharedStore.organizationId
      
      if let content = content {
        contentId = content.id
        contentType = content.contentTypeString
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
          params["attributes"] = attributes
        }
        
        if let beacon = playerInfo,
          let player = beacon.playerType,
          let elapsed = beacon.elapsed {
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
