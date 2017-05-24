//
//  OddExternal.swift
//  Odd-iOS
//
//  Created by Patrick McConnell on 12/2/15.
//  Copyright © 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

@objc open class OddExternal: OddMediaObject {
  
  var sourceURL: String?
  
  class func externalFromJson( _ json: jsonObject ) -> OddExternal {
    let newExternal = OddExternal()
    newExternal.configureWithJson(json)
    
    newExternal.defaultTitle = "Odd Networks External"
    newExternal.defaultSubtitle = "Another fine external from Odd Networks"
    
    return newExternal
  }
  
  override func configureWithJson(_ json: jsonObject) {
    super.configureWithJson(json)
    addAdditionalMetaData(json)
  }
  
  func addAdditionalMetaData(_ json: jsonObject) {
    if let attributes = json["attributes"] as? jsonObject {
      self.sourceURL = attributes["url"] as? String
    }
  }
}
