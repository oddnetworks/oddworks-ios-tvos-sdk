//
//  StringExtensions.swift
//  srp_app_ios
//
//  Created by Patrick McConnell on 12/15/14.
//  Copyright (c) 2014 Patrick McConnell. All rights reserved.

import UIKit

extension String {
  func toDateFromRailsJSON(time: Bool = false) -> NSDate? {
    let formater = NSDateFormatter()
    if time {
      formater.timeZone = NSTimeZone(forSecondsFromGMT: 0)
      formater.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    } else {
      formater.dateFormat = "yyyy-MM-dd"
    }
    
    return formater.dateFromString(self)
  }
  
  func toDateFromFormatString(formatString: String) -> NSDate? {
    let formater = NSDateFormatter()
    formater.dateFormat = formatString
    
    return formater.dateFromString(self)
  }
  
}

