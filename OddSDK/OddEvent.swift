//
//  OddEvent.swift
//  Odd-iOS
//
//  Created by Matthew Barth on 12/2/15.
//  Copyright © 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit
import WebKit

@objc open class OddEvent: OddMediaObject {
  
  var category: String?
  var source: String?
  var createdAt: String?
  var sourceURL: String?
  var location: String?
  var startDate: String?
  var endDate: String?
  
  override var contentTypeString: String { return "event" }
  
  override var cellReuseIdentifier: String { return "eventCell" }
  override var cellHeight: CGFloat { return 80 }
  
  class func eventFromJson( _ json: jsonObject) -> OddEvent {
    let newArticle = OddEvent()
    newArticle.configureWithJson(json)
    
    newArticle.defaultTitle = "Odd Networks Event"
    newArticle.defaultSubtitle = "Another fine event from Odd Networks"
    
    return newArticle
  }
  
  override func configureWithJson(_ json: jsonObject) {
    super.configureWithJson(json)
    addAdditionalMetaData(json)
  }
  
  func addAdditionalMetaData(_ json: jsonObject) {
    if let attributes = json["attributes"] as? jsonObject, let ical = attributes["ical"] as? jsonObject, let source = attributes["source"] as? jsonObject {
      self.category = attributes["category"] as? String
      self.source = source["url"] as? String
      self.createdAt = attributes["createdAt"] as? String
      self.sourceURL = attributes["url"] as? String
      self.location = ical["location"] as? String
      self.startDate = ical["dtstart"] as? String
      self.endDate = ical["dtend"] as? String
    }
  }
    
  func eventDateString() -> String {
    if let start = self.startDate,
      let end = self.endDate,
      let formattedStartDate = start.toDateFromFormatString("yyyy-MM-dd'T'HH:mm:ssZ"),
      let formattedEndDate = end.toDateFromFormatString("yyyy-MM-dd'T'HH:mm:ssZ") {
    
        let mediumStart = formattedStartDate.mediumFormatString()
        let mediumEnd = formattedEndDate.mediumFormatString()
        
        return "\(mediumStart) - \(mediumEnd)"
    }
    return ""
  }
  
  
}
