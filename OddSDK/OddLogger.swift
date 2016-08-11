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
  
  public static var tag : String = ""
  
  public static var logLevel: OddLogLevel = .error
  
  private static func formattedTag() -> String {
    return self.tag.isEmpty ? "" : "\(self.tag): "
  }
  
  private static func log(glyph: String, message: String) {
    if tag.isEmpty {
      print("\(glyph) \(message)")
    } else {
      print("\(glyph) \(tag): \(message)")
    }
    
  }
  
  public static func info(_ message: String) {
    if OddLogger.logLevel.atLeast(.info)   {
      log(glyph: "✅", message: message)
    }
  }
  
  public static func warn(_ message: String) {
    if OddLogger.logLevel.atLeast(.warn)  {
      log(glyph: "⚠️", message: message)
    }
  }
  
  public static func error(_ message: String) {
    log(glyph: "❌", message: message)
  }
}
