//
//  OddSDKTests.swift
//  OddSDKTests
//
//  Created by Patrick McConnell on 4/22/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//
// http://masilotti.com/xctest-documentation/
//

import XCTest
@testable import OddSDK

class OddSDKTests: XCTestCase {
  
  func registerForNotifications() {
    print("Registering For Notifications")
    NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(OddSDKTests.configLoaded), name: OddConstants.OddFetchedConfigNotification, object: nil)
  }
  
  func configLoaded() {
    print("@@@@@@@@@@@@@@@@@@ CONFIG LOADED @@@@@@@@@@@@@@@@@@@")
  }
  
  func initializeSDK() {
    registerForNotifications()
    
    OddContentStore.sharedStore.API.serverMode = .Local
    
    //    Uncomment to see additional log messages from the SDK.
    OddLogger.logLevel = .Info
    
    //    Enter your authToken here
    OddContentStore.sharedStore.API.authToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ2ZXJzaW9uIjoxLCJjaGFubmVsIjoibmFzYSIsInBsYXRmb3JtIjoiYXBwbGUtaW9zIiwic2NvcGUiOlsicGxhdGZvcm0iXSwiaWF0IjoxNDYxMzMxNTI5fQ.lsVlk7ftYKxxrYTdl8rP-dCUfk9odhCxvwm9jsUE1dU"
    
    OddContentStore.sharedStore.initialize()
  }
  
  override func setUp() {
    super.setUp()
    initializeSDK()
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
    OddContentStore.sharedStore.resetStore()
  }
  
  
  func testCanFetchConfig() {
    let okExpectation = expectationWithDescription("ok")
    
    var configFound = false
    
    while !configFound {
      guard let config = OddContentStore.sharedStore.config else { continue }
      configFound = true
      XCTAssertNotNil(config, "SDK should load config")
      okExpectation.fulfill()
    }

    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  
//  DataSource *dataSource = [[DataSource alloc] init];
//  [dataSource loadData];
//  XCTestExpectation *expectation = [self expectationWithDescription:@"Dummy expectation"];
//  dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//  XCTAssert(dataSource.dataArray.count > 0, @"Data source has populated array after initializing and, you know, giving it some time to breath, man.");
//  [expectation fulfill];
//  });
//  [self waitForExpectationsWithTimeout:20.0 handler:nil];
  
}
