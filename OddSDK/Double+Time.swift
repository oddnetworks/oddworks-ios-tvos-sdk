//
//  NSTimeInterval+String.swift
//  
//
//  Created by Patrick McConnell on 9/1/15.
//  Copyright (c) 2015 Patrick McConnell. All rights reserved.
//

import Foundation

extension Double {

  func stringFromTimeInterval() -> String {
    let interval = Int(self)
    let seconds = interval % 60
    let minutes = (interval / 60) % 60
    let hours = (interval / 3600)
    if hours > 0 {
      return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    } else {
      return String(format: "%02d:%02d", minutes, seconds)
    }
  }
  
  func millisecondsFromTimeInterval() -> Int {
    let interval = Int(self)
    let seconds = interval % 60
    let milliseconds = seconds * 1000
    return milliseconds
  }
  
  func roundTimeForMetrics() -> Int {
    return Int(self/100) * 100
  }
  
}
