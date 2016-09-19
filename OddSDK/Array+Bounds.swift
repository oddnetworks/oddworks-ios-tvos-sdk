//
//  Array+Bounds.swift
//  Odd-iOS
//
//  Created by Patrick McConnell on 11/20/15.
//  Copyright © 2015 Patrick McConnell. All rights reserved.
//

import Foundation

// throws an error if an index used to subscript into an array 
// is out of bounds.
// http://ericasadun.com/2015/06/09/swift-why-try-and-catch-dont-work-the-way-you-expect/

public extension Array {
  public func lookup(_ index : UInt) throws -> Element {
    if Int(index) >= count {throw
      NSError(domain: "com.sadun", code: 0,
        userInfo: [NSLocalizedFailureReasonErrorKey:
          "Array index out of bounds"])}
    return self[Int(index)]
 }
}
