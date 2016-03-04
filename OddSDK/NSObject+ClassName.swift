//
//  ClassHelpers.swift
//  PokerCentral
//
//  Created by Patrick McConnell on 8/19/15.
//  Copyright (c) 2015 Patrick McConnell. All rights reserved.
//

import UIKit

extension NSObject{
  class var nameOfClass: String{
    return NSStringFromClass(self).componentsSeparatedByString(".").last!
  }
  
  var nameOfClass: String{
    return NSStringFromClass(self.dynamicType).componentsSeparatedByString(".").last!
  }
}