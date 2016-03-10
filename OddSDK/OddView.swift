//
//  OddView.swift
//  
//
//  Created by Patrick McConnell on 7/31/15.
//  Copyright (c) 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

class OddView: NSObject {
  var featuredPromotion: OddPromotion?
  var featuredMediaObject: OddMediaObject?
  var featuredVideos: Array<OddVideo>?
  var featuredVideoCollections : Array<OddMediaObjectCollection>?
  var generatedVideoCollections: Array<OddMediaObjectCollection>?
  
  class func oddViewFromJson(json : Dictionary<String, AnyObject>) -> OddView {
    let newOddView = OddView()
    
    
    return newOddView
  }
   
}
