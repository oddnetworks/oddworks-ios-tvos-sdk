//
//  ClassHelpers.swift
//  
//
//  Created by Patrick McConnell on 8/19/15.
//  Copyright (c) 2015 Patrick McConnell. All rights reserved.
//

import UIKit

extension NSObject{
  class var nameOfClass: String{
    return NSStringFromClass(self).components(separatedBy: ".").last!
  }
  
  var nameOfClass: String{
    return NSStringFromClass(type(of: self)).components(separatedBy: ".").last!
  }
}
