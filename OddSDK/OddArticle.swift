//
//  OddArticle.swift
//  Odd-iOS
//
//  Created by Patrick McConnell on 11/30/15.
//  Copyright © 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit
import WebKit

@objc open class OddArticle: OddMediaObject {
  
  var category: String?
  var source: String?
  var createdAt: String?
  var sourceURL: String?
  
  override var contentTypeString: String { return "article" }
  
  override var cellReuseIdentifier: String { return "mediaInfoCell" }
  override var cellHeight: CGFloat { return 80 }
  
  class func articleFromJson( _ json: jsonObject) -> OddArticle {
    let newArticle = OddArticle()
    newArticle.configureWithJson(json)
    
    newArticle.defaultTitle = "Odd Networks Article"
    newArticle.defaultSubtitle = "Another fine article from Odd Networks"
    
    return newArticle
  }
  
  override func configureWithJson(_ json: jsonObject) {
    super.configureWithJson(json)
    addAdditionalMetaData(json)
  }
  
  func addAdditionalMetaData(_ json: jsonObject) {
    if let attributes = json["attributes"] as? jsonObject, let source = attributes["source"] as? jsonObject {
      self.category = attributes["category"] as? String
      self.source = source["url"] as? String
      self.createdAt = attributes["createdAt"] as? String
      self.sourceURL = attributes["url"] as? String
    }
  }
  
}
