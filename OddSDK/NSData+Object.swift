//
//  NSData+Object.swift
//  OddSDK
//
//  Created by Patrick McConnell on 1/29/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import Foundation

// A collection of class helpers to convert Structs or Class objects to NSData

extension NSData {
  class func encodeObject<T>(var value: T) -> NSData {
    return withUnsafePointer(&value) { p in
      NSData(bytes: p, length: sizeofValue(value))
    }
  }
  
  class func decodeData<T>(data: NSData) -> T {
    let pointer = UnsafeMutablePointer<T>.alloc(sizeof(T.Type))
    data.getBytes(pointer, length: sizeof(T) )
    
    return pointer.move()
  }
}
