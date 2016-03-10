//
//  OddPromotion.swift
//  
//
//  Created by Patrick McConnell on 7/31/15.
//  Copyright (c) 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

@objc public class OddPromotion: OddMediaObject {
  
  var timer: Double = 3.0
  var imageLink_16x9: String?
  var imageLink_1x1: String?
  var imageLink_2x3: String?
  var imageLink_3x4: String?
  var imageLink_4x3: String?
  
  override var contentTypeString: String { return "promotion" }
  
  class func promotionFromJson( json: jsonObject) -> OddPromotion {
    let newPromo = OddPromotion()
    newPromo.configureWithJson(json)
    
    if let attribs = json["attributes"] as? jsonObject, images = attribs["images"] as? jsonObject  {
      newPromo.imageLink_16x9 = images["aspect16x9"] as? String
      newPromo.imageLink_1x1 = images["aspect1x1"] as? String
      newPromo.imageLink_2x3 = images["aspect2x3"] as? String
      newPromo.imageLink_3x4 = images["aspect3x4"] as? String
      newPromo.imageLink_4x3 = images["aspect4x3"] as? String
    }

    return newPromo
  }
  
   
}
