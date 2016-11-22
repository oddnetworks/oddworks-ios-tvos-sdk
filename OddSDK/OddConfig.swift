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
  
  mutating func configureWithJSON(_ json : jsonObject) {
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
      self.provider = .none
    }
  }
}

public struct EventSettings {
  public var action: OddMetricAction
  public var actionString: String
  public var enabled: Bool
  public var interval: Double?
}

public struct EventsConfiguration {
  var enabledStats: Array<EventSettings> = [
    EventSettings(action: .AppInit, actionString: "app:init", enabled: true, interval: nil),
    EventSettings(action: .ViewLoad, actionString: "view:load", enabled: true, interval: nil),
    EventSettings(action: .VideoLoad, actionString: "video:load", enabled: true, interval: nil),
    EventSettings(action: .VideoPlay, actionString: "video:play", enabled: true, interval: nil),
    EventSettings(action: .VideoPlaying, actionString: "video:playing", enabled: true, interval: 3),
    EventSettings(action: .VideoStop, actionString: "video:stop", enabled: true, interval: nil),
    EventSettings(action: .VideoError, actionString: "video:error", enabled: true, interval: nil),
    EventSettings(action: .UserNew, actionString: "user:new", enabled: true, interval: nil)
  ]
  
  mutating func configureWithJSON(_ metrics: jsonObject) {
    
    func appendIfEnabled(_ actionName: String) {
      if let metric = metrics[actionName] as? Dictionary<String, AnyObject>,
        let actionString = metric["action"] as? String,
        let enabled = metric["enabled"] as? Bool,
        let action = OddMetricAction(rawValue: actionName) {
        var adjustedInterval: Double? = nil
        if let interval = metric["interval"] as? Double {
          adjustedInterval = interval / 1000
        }
        let metricStat = EventSettings(action: action, actionString: actionString, enabled: enabled, interval: adjustedInterval )
        enabledStats.append(metricStat)
      }
    }
    
    enabledStats.removeAll()
    //appInit
    appendIfEnabled("appInit")
    appendIfEnabled("viewLoad")
    appendIfEnabled("videoLoad")
    appendIfEnabled("videoPlay")
    appendIfEnabled("videoPlaying")
    appendIfEnabled("videoStop")
    appendIfEnabled("videoError")
    appendIfEnabled("userNew")
  }
 
  public func findEnabled(_ action: OddMetricAction) -> EventSettings? {
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
  public var analyticsManager = EventsConfiguration()
  var adManager = AdServiceConfiguration()
  var requiresAuthentication: Bool = false
  
  class func configFromJson( _ json : Dictionary<String, AnyObject> ) -> OddConfig? {
    let newConfig = OddConfig()
    guard let data = json["data"] as? Dictionary<String, AnyObject>,
      let attribs = data["attributes"] as? Dictionary<String, AnyObject>,
      let viewJson = attribs["views"] as? Dictionary<String, AnyObject> else {
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
  public func idForViewName(_ viewName: String) -> String? {
    if let keys = viewNames() {
      if keys.contains(viewName) {
        return self.views![viewName]! as? String
      }
    }
    return nil
  }

}
