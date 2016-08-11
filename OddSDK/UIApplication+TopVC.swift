//
//  UIApplication+TopVC.swift
//  
//
//  Created by Patrick McConnell on 9/11/15.
//  Copyright (c) 2015 Patrick McConnell. All rights reserved.
//

import Foundation
import UIKit

extension UIApplication {
  class func topViewController(_ base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
    
    if let nav = base as? UINavigationController {
      return topViewController(nav.visibleViewController)
    }
    
    if let tab = base as? UITabBarController {
      #if os(iOS)
      let moreNavigationController = tab.moreNavigationController
      
      if let top = moreNavigationController.topViewController, top.view.window != nil {
        return topViewController(top)
      } else if let selected = tab.selectedViewController {
        return topViewController(selected)
      }
      #else
        guard let selected = tab.selectedViewController else { return nil }
        return topViewController(selected)
      #endif
      
    }
    
    if let presented = base?.presentedViewController {
      return topViewController(presented)
    }
    
    return base
  }
}
