//
//  NSDate+String.swift
//  srp_app_ios
//
//  Created by Patrick McConnell on 12/15/14.
//  Copyright (c) 2014 Patrick McConnell. All rights reserved.
//

import Foundation

extension NSDate {
  func shortFormatString() -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateStyle = .ShortStyle

    return dateFormatter.stringFromDate(self)
  }
  
  func shortFormatStringWithTime() -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateStyle = .ShortStyle
    dateFormatter.timeStyle = .ShortStyle
    
    return dateFormatter.stringFromDate(self)
  }

  func mediumFormatString() -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateStyle = .MediumStyle
    
    return dateFormatter.stringFromDate(self)
  }
  
  func mediumFormatStringWithTime() -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateStyle = .MediumStyle
    dateFormatter.timeStyle = .MediumStyle
    
    return dateFormatter.stringFromDate(self)
  }

  func longFormatString() -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateStyle = .LongStyle
    
    return dateFormatter.stringFromDate(self)
  }
  
  func longFormatStringWithTime() -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateStyle = .LongStyle
    dateFormatter.timeStyle = .LongStyle
    
    return dateFormatter.stringFromDate(self)
  }
  
  func yyyyMMddFormatString() -> String {
    let dateFormatter = NSDateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.stringFromDate(self)
  }
  
  func timeOnly() -> String {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "h:mm a"
    
    return formatter.stringFromDate(self)
  }
  
}