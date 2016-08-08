//
//  NSDate+String.swift
//  srp_app_ios
//
//  Created by Patrick McConnell on 12/15/14.
//  Copyright (c) 2014 Patrick McConnell. All rights reserved.
//

import Foundation

extension Date {
  func shortFormatString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short

    return dateFormatter.string(from: self)
  }
  
  func shortFormatStringWithTime() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short
    
    return dateFormatter.string(from: self)
  }

  func mediumFormatString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    
    return dateFormatter.string(from: self)
  }
  
  func mediumFormatStringWithTime() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium
    
    return dateFormatter.string(from: self)
  }

  func longFormatString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    
    return dateFormatter.string(from: self)
  }
  
  func longFormatStringWithTime() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .long
    
    return dateFormatter.string(from: self)
  }
  
  func yyyyMMddFormatString() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.string(from: self)
  }
  
  func timeOnly() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    
    return formatter.string(from: self)
  }
  
}
