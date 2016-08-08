//
//  NSURL+query.swift
//  Odd-iOS
//
//  Created by Patrick McConnell on 10/23/15.
//  Copyright © 2015 Patrick McConnell. All rights reserved.
//

import UIKit

// hat tip to http://blog.matthewcheok.com/parsing-query-parameters/

extension URL {
  var queryDictionary: [String:String]? {
    if let query = self.query {
      var dict = [String:String]()
      for parameter in query.components(separatedBy: "&") {
        let components = parameter.components(separatedBy: "=")
        if components.count == 2 {
          let key = components[0].removingPercentEncoding!
          let value = components[1].removingPercentEncoding!
          dict[key] = value
        }
      }
      return dict
    }
    else {
      return nil
    }
  }
}
