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
  
  func glyph() -> String {
    switch self {
    case .info: return "✅"
    case .warn: return "⚠️"
    case .error: return "❌"
    }
  }
  
  func atLeast(_ level: OddLogLevel) -> Bool {
    return level.rawValue >= self.rawValue
  }
}

open class OddLogger: NSObject {
  
  open static var tag : String = ""
  
  open static var logLevel: OddLogLevel = .error
  
  fileprivate static func formattedTag() -> String {
    return self.tag.isEmpty ? "" : "\(self.tag): "
  }
  
  fileprivate static func log( _ message: String) {
    if tag.isEmpty {
      print("\(logLevel.glyph()) \(message)")
    } else {
      print("\(logLevel.glyph()) \(tag): \(message)")
    }
    
  }
  
  open static func info(_ message: String) {
    if OddLogger.logLevel.atLeast(.info)   {
      log(message)
    }
  }
  
  open static func warn(_ message: String) {
    if OddLogger.logLevel.atLeast(.warn)  {
      log(message)
    }
  }
  
  open static func error(_ message: String) {
    log(message)
  }
  
  // grabs the topmost viewController and presents an alert dialog to the user
  open static func showAlert(withTitle title: String, message: String, kind: OddLogLevel? = nil) {
    let decoratedTitle = kind != nil ? "\(kind!.glyph()) \(title)" : title
    guard let topVC = UIApplication.topViewController() else { return }
    let alert = UIAlertController(title: decoratedTitle, message: message, preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
      alert.removeFromParentViewController()
//      topVC.dismissViewControllerAnimated(true, completion: {
//        
//      })
    })
    alert.addAction(okAction)
    DispatchQueue.main.async { 
      topVC.present(alert, animated: true, completion: { print("done") })  
    }
    
  }
  
  
  //ERRORS
  open static func showErrorAlert(_ error: String) {
    OddLogger.showAlert(withTitle: "Error", message: error, kind: .error)
  }
  
  open static func logAndDisplayError(_ error: String) {
    OddLogger.error(error)
    OddLogger.showErrorAlert(error)
  }
  
  //WARNINGS
  open static func showWarningAlert(_ warning: String) {
    OddLogger.showAlert(withTitle: "Warning", message: warning, kind: .warn)
  }
  
  open static func logAndDisplayWarning(_ warning: String) {
    OddLogger.error(warning)
    OddLogger.showWarningAlert(warning)
  }
  
  //INFO
  open static func showInfoAlert(_ info: String) {
    OddLogger.showAlert(withTitle: "Information", message: info, kind: .info)
  }
  
  open static func logAndDisplayInfo(_ info: String) {
    OddLogger.info(info)
    OddLogger.showInfoAlert(info)
  }
  
  
  
}
