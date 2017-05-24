//
//  StringExtensions.swift
//  srp_app_ios
//
//  Created by Patrick McConnell on 12/15/14.
//  Copyright (c) 2014 Patrick McConnell. All rights reserved.

import UIKit

extension String {
  func toDateFromRailsJSON(_ time: Bool = false) -> Date? {
    let formater = DateFormatter()
    if time {
      formater.timeZone = TimeZone(secondsFromGMT: 0)
      formater.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    } else {
      formater.dateFormat = "yyyy-MM-dd"
    }
    
    return formater.date(from: self)
  }
  
  func toDateFromFormatString(_ formatString: String) -> Date? {
    let formater = DateFormatter()
    formater.dateFormat = formatString
    
    return formater.date(from: self)
  }
  
}

