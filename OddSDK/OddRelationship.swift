//
//  OddRelationship.swift
//  OddSDK
//
//  Created by Patrick McConnell on 5/3/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import UIKit

public struct OddRelationship: Hashable, Equatable {
  public var id: String
  public var mediaObjectType: OddMediaObjectType
  
  public var hashValue: Int {
    return id.hashValue
  }
  
  public static func ==(lhs: OddRelationship, rhs: OddRelationship) -> Bool {
    return lhs.id == rhs.id && lhs.mediaObjectType == rhs.mediaObjectType
  }
}

public struct OddRelationshipNode {
  var single: OddRelationship?
  var multiple: Array<OddRelationship>?
  public var numberOfRelationships: Int {
    get {
      if self.single != nil {
        return 1
      } else if self.multiple != nil {
        return self.multiple!.count
      }
      
      return 0
    }
  }
  
  public var allIds: Array<String>? {
    get {
      if self.single != nil {
        return [self.single!.id]
      } else if self.multiple != nil {
        return self.multiple!.map({$0.id})
      }
      
      return nil
    }
  }
  
  public func idsOfType(_ type: OddMediaObjectType) -> Array<String>? {
    if let single = self.single {
      if single.mediaObjectType == type {
        return [single.id]
      }
    }
    if let multiple = multiple {
      let nodes = multiple.filter({$0.mediaObjectType == type})
      return nodes.map({$0.id})
    }
    return nil
  }
  
  public var allTypes: Set<OddMediaObjectType> {
    if let single = self.single {
      return [single.mediaObjectType]
    }
    if let multiple = multiple {
      var types = Array<OddMediaObjectType>()
      multiple.forEach({ (relationship) in
        types.append(relationship.mediaObjectType)
      })
      return Set(types)
    }
    return []
  }
  
  public func getAllObjects(_ callback: @escaping (_ objects: Array<OddMediaObject>, _ errors: Array<NSError>?) ->()) {
    let types = self.allTypes
    var allObjects: Array<OddMediaObject> = []
    var allErrors: Array<NSError> = []
    for (i, type) in types.enumerated() {
      guard let ids = idsOfType(type) else { break }
    
      let includeParam: String? = type == .collection ? "entities": nil
      OddContentStore.sharedStore.objectsOfType(type, ids: ids, include: includeParam, callback: { (objects, errors) in
        if errors != nil {
          OddLogger.error("Error loading: \(ids)")
          errors?.forEach({allErrors.append($0)})
        }
        allObjects.append(contentsOf: objects)
        
        if allErrors.count + allObjects.count == self.allIds?.count {
            print("Types: \(i + 1) Objects: \(allObjects.count)")
          var sortedResults: Array<OddMediaObject> = []
          self.allIds?.forEach({ (id) in
            allObjects.forEach({ (obj) in
              if obj.id == id {
                sortedResults.append(obj)
              }
            })
          })
          
          callback(sortedResults, allErrors.isEmpty ? nil : allErrors)
        }
      })
    }
  }
  
  public var relationship: Any? {
    get {
      return single != nil ? single : multiple
    }
  }
}
