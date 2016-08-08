//
//  OddView.swift
//  
//
//  Created by Patrick McConnell on 7/31/15.
//  Copyright (c) 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

@objc public class OddView: OddMediaObject {

  class func viewFromJson(_ json : jsonObject) -> OddView {
    let newView = OddView()
    newView.configureWithJson(json)
    
    return newView
  }
  
//  override func configureWithJson(json: jsonObject) {
//    super.configureWithJson(json)
//    addAdditionalMetaData(json)
//  }
//  
//  func addAdditionalMetaData(json: jsonObject) {
//  }
  
}
