//
//  OddSDKPerformanceTests.swift
//  OddSDK
//
//  Created by Patrick McConnell on 5/3/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//

import XCTest

class OddSDKPerformanceTests: XCTestCase {
  
  func configureSDK() {
    OddContentStore.sharedStore.API.serverMode = .local
    
    OddLogger.logLevel = .info
    
    OddContentStore.sharedStore.API.authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ2ZXJzaW9uIjoxLCJjaGFubmVsIjoibmFzYSIsInBsYXRmb3JtIjoiYXBwbGUtaW9zIiwic2NvcGUiOlsicGxhdGZvcm0iXSwiaWF0IjoxNDYxMzMxNTI5fQ.lsVlk7ftYKxxrYTdl8rP-dCUfk9odhCxvwm9jsUE1dU"
  }
  
  override func setUp() {
    super.setUp()
    configureSDK()
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
    OddContentStore.sharedStore.resetStore()
  }
  
  
  func testInitialize() {
    // This is an example of a performance test case.
    self.measure {
      OddContentStore.sharedStore.initialize { (success, error) in
        if success {
          print("initialize success")
        }
      }
    }
  }
  
  func testFetchViewNoInclude() {
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        self.measure {
          OddContentStore.sharedStore.objectsOfType(.view, ids: [homeViewId], include: nil, callback: { (objects, errors) in
            print("loaded view")
          })
        }
      }
    }
  }
  
  func testFetchViewWithInclude() {
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        self.measure {
          OddContentStore.sharedStore.objectsOfType(.view, ids: [homeViewId], include: "featuredMedia,featuredCollections,promotion", callback: { (objects, errors) in
            print("loaded view")
          })
        }
        
      }
    }
  }
  
  func testFetchCollectionNoInclude() {
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let collectionId = "ab2d92ee98b6309299e92024a487d4c0"
        self.measure {
          OddContentStore.sharedStore.objectsOfType(.collection, ids: [collectionId], include: "nil", callback: { (objects, errors) in
            print("loaded collection")
          })
        }
      }
    }
  }
  
  func testFetchCollectionWithInclude() {
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let collectionId = "ab2d92ee98b6309299e92024a487d4c0"
        self.measure {
          OddContentStore.sharedStore.objectsOfType(.collection, ids: [collectionId], include: "entities", callback: { (objects, errors) in
            print("loaded collection")
          })
        }
      }
    }
  }
  
}
