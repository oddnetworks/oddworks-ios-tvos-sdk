//
//  OddConfig.swift
//  
//
//  Created by Patrick McConnell on 7/31/15.
//  Copyright (c) 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

enum AdProvider : String {
  case Google     = "google"
  case Freewheel  = "freewheel"
  case None       = "none"
}

struct AdServiceConfiguration {
  var provider: AdProvider!
  var url: String?
  var format: String?
  var networkId: Int?
  var vHost: String?
  var profileName: String?
  var siteSectionId: String?
//  var adManagerUrl: String?
  
  mutating func configureWithJSON(json : jsonObject) {
    if let provider = json["provider"] as? String {
      self.provider       =  AdProvider(rawValue: provider)
      self.url            = json["url"] as? String
      self.format         = json["format"] as? String
      self.networkId      = json["networkId"] as? Int
      self.vHost          = json["vHost"] as? String
      self.profileName    = json["profileName"] as? String
      self.siteSectionId  = json["siteSectionId"] as? String
//      self.adManagerUrl   = json["adManagerUrl"] as? String
    } else {
      self.provider = .None
    }
  }
}

struct EventSettings {
  var action: OddMetricAction
  var actionString: String
  var enabled: Bool
  var interval: Double?
}

struct EventsConfiguration {
  var enabledStats: Array<EventSettings> = [
      EventSettings(action: .AppInit, actionString: "app:init", enabled: true, interval: nil),
      EventSettings(action: .ViewLoad, actionString: "view:load", enabled: true, interval: nil),
      EventSettings(action: .VideoPlay, actionString: "video:play", enabled: true, interval: nil),
      EventSettings(action: .VideoPlaying, actionString: "video:playing", enabled: true, interval: 3),
      EventSettings(action: .VideoStop, actionString: "video:stop", enabled: true, interval: nil),
      EventSettings(action: .VideoError, actionString: "video:error", enabled: true, interval: nil)
  ]
  
  mutating func configureWithJSON(metrics: jsonObject) {
    enabledStats.removeAll()
    //appInit
    if let videoPlay = metrics["appInit"] as? Dictionary<String, AnyObject>, actionString = videoPlay["action"] as? String, enabled = videoPlay["enabled"] as? Bool {
      let appInitStat = EventSettings(action: .AppInit, actionString: actionString, enabled: enabled, interval: nil)
      enabledStats.append(appInitStat)
    }
    
    //viewLoad
    if let viewLoad = metrics["viewLoad"] as? Dictionary<String, AnyObject>, actionString = viewLoad["action"] as? String, enabled = viewLoad["enabled"] as? Bool {
      let viewLoadStat = EventSettings(action: .ViewLoad, actionString: actionString, enabled: enabled, interval: nil)
      enabledStats.append(viewLoadStat)
    }
    
    //videoPlay
    if let videoPlay = metrics["videoPlay"] as? Dictionary<String, AnyObject>, actionString = videoPlay["action"] as? String, enabled = videoPlay["enabled"] as? Bool {
      let videoPlayStat = EventSettings(action: .VideoPlay, actionString: actionString, enabled: enabled, interval: nil)
      enabledStats.append(videoPlayStat)
    }
    
    //videoPlaying
    if let videoPlaying = metrics["videoPlaying"] as? Dictionary<String, AnyObject>, actionString = videoPlaying["action"] as? String, enabled = videoPlaying["enabled"] as? Bool, interval = videoPlaying["interval"] as? Double  {
      //given in milliseconds, timer takes seconds
      let convertedInterval = interval / 1000
      let videoPlayingStat = EventSettings(action: .VideoPlaying, actionString: actionString, enabled: enabled, interval: convertedInterval)
      enabledStats.append(videoPlayingStat)
    }
    
    //videoStop
    if let videoStop = metrics["videoStop"] as? Dictionary<String, AnyObject>, actionString = videoStop["action"] as? String, enabled = videoStop["enabled"] as? Bool {
      let videoStopStat = EventSettings(action: .VideoStop, actionString: actionString, enabled: enabled, interval: nil)
      enabledStats.append(videoStopStat)
    }
    
    //videoError
    if let videoError = metrics["videoError"] as? Dictionary<String, AnyObject>, actionString = videoError["action"] as? String, enabled = videoError["enabled"] as? Bool {
      let videoErrorStat = EventSettings(action: .VideoError, actionString: actionString, enabled: enabled, interval: nil)
      enabledStats.append(videoErrorStat)
    }
  }
  
  func findEnabled(action: OddMetricAction) -> EventSettings? {
    var relevantStat: EventSettings?
    enabledStats.forEach({ (stat: EventSettings) in
      if stat.action == action && stat.enabled == true {
        relevantStat = stat
      }
    })
    return relevantStat != nil ? relevantStat! : nil
  }
}

@objc public class OddConfig: NSObject {
  var views: jsonObject?
//  var homeViewId: String?
//  var splashViewId: String?
//  var menuViewId: String?
  var analyticsManager = EventsConfiguration()
  var adManager = AdServiceConfiguration()
  var requiresAuthentication: Bool = false
  
  class func configFromJson( json : Dictionary<String, AnyObject> ) -> OddConfig? {
    let newConfig = OddConfig()
    guard let data = json["data"] as? Dictionary<String, AnyObject>,
      attribs = data["attributes"] as? Dictionary<String, AnyObject>,
      viewJson = attribs["views"] as? Dictionary<String, AnyObject> else {
        return newConfig
    }
    
    newConfig.views = viewJson
//    if let data = json["data"] as? Dictionary<String, AnyObject>, attribs = data["attributes"] as? Dictionary<String, AnyObject>, views = attribs["views"] as? Dictionary<String, AnyObject> {
//      newConfig.homeViewId = views["homepage"] as? String
//      newConfig.splashViewId = views["splash"] as? String
//      newConfig.menuViewId = views["menu"] as? String
    
    //MARK: FEATURES
    if let features = attribs["features"] as? Dictionary<String, AnyObject> {
      //Mark: Ads
      if let ads = features["ads"] as? Dictionary<String, AnyObject> {
        newConfig.adManager.configureWithJSON(ads)
      } //end ads
      
      //Mark: Metrics
      if let metrics = features["metrics"] as? Dictionary<String, AnyObject> {
        newConfig.analyticsManager.configureWithJSON(metrics)
      }

      // authentication -> enabled only used for fully paywalled applications
//        MARK: Authentication
      if let auth = features["authentication"] as? Dictionary<String, AnyObject> {
        newConfig.requiresAuthentication = auth["enabled"] as! Bool
//          AuthenticationCredentials.credentialsFromJson(auth)
      }
    
    } // end features
    
    return newConfig
  }

  /// Convenience method to retun all view names in the
  /// views dictionary
  public func viewNames() -> Set<String>? {
    var result = Set<String>()
    if let views = self.views {
      views.keys.forEach({ (key) -> () in
        result.insert(key)
      })
      return result
    }
    return nil
  }

  /// Convenience method to return a given views id
  /// or nil if it is not found
  public func idForViewName(viewName: String) -> String? {
    if let keys = viewNames() {
      if keys.contains(viewName) {
        return self.views![viewName]! as? String
      }
    }
    return nil
  }

}
