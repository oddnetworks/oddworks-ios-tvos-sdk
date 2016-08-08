//
//  OddLogger.swift
//  OddSDK
//
//  Created by Patrick McConnell on 1/6/16.
//  Copyright © 2016 Odd Networks, LLC. All rights reserved.
//

import UIKit

/// The level of logging to be displayed on the console.
/// Levels in order are 
@objc public enum OddLogLevel: Int {
  case info
  case warn
  case error
  
  func atLeast(_ level: OddLogLevel) -> Bool {
    return level.rawValue >= self.rawValue
  }
}

public class OddLogger: NSObject {

  public static var logLevel: OddLogLevel = .error
  
  public static func info(_ message: String) {
    if OddLogger.logLevel.atLeast(.info)   {
      print("✅ \(message)")
    }
  }
  
  public static func warn(_ message: String) {
    if OddLogger.logLevel.atLeast(.warn)  {
      print("⚠️ \(message)")
    }
  }
  
  public static func error(_ message: String) {
    print("❌ \(message)")
  }
}
