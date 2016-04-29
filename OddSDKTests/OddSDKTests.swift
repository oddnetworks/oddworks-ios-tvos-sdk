//
//  OddSDKTests.swift
//  OddSDKTests
//
//  Created by Patrick McConnell on 4/22/16.
//  Copyright © 2016 Patrick McConnell. All rights reserved.
//
// http://masilotti.com/xctest-documentation/
//
//
// NOTE ABOUT THESE TESTS
//
// Tests are setup to be full 'end to end' tests hitting a real server
// These tests should be run against a copy of the most recent
// Oddworks server using the NASA data
//
// https://github.com/oddnetworks/oddworks
// The 'nasa_data' tag can be used as a reference
//

import XCTest
@testable import OddSDK

class OddSDKTests: XCTestCase {
  
  func configureSDK() {
    OddContentStore.sharedStore.API.serverMode = .Local
    
    OddLogger.logLevel = .Info
    
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
  
  
  func testCanFetchConfig() {
    let okExpectation = expectationWithDescription("ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config else { return }
        XCTAssertNotNil(config, "SDK should load config")
        XCTAssertEqual(config.viewNames()?.count, 3, "Config should have correct number of views")
        okExpectation.fulfill()
      }
    }
    
    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testConfigHasCorrectViews() {
    let okExpectation = expectationWithDescription("ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config else { return }
        XCTAssertEqual(config.viewNames()?.count, 3, "Config should have correct number of views")
        XCTAssertEqual(config.idForViewName("homepage"), "homepage", "Config should have the correct views")
        XCTAssertEqual(config.idForViewName("splash"), "splash", "Config should have the correct views")
        XCTAssertEqual(config.idForViewName("menu"), "menu", "Config should have the correct views")
        okExpectation.fulfill()
      }
    }
    
    waitForExpectationsWithTimeout(5, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testCanLoadHomeView() {
    let okExpectation = expectationWithDescription("ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        OddContentStore.sharedStore.objectsOfType(.View, ids: [homeViewId], include: nil, callback: { (objects, errors) in
          guard let view = objects.first as? OddView else { return }
          XCTAssertNotNil(view, "SDK should load a view")
          XCTAssertEqual(view.id, "homepage", "Config should have correct home view id")
          XCTAssertEqual(view.title, "Nasa Sample Homepage", "Config should have correct home view title")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectationsWithTimeout(10, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testHomeViewHasCorrectRelationships() {
    let okExpectation = expectationWithDescription("ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        OddContentStore.sharedStore.objectsOfType(.View, ids: [homeViewId], include: nil, callback: { (objects, errors) in
          guard let view = objects.first as? OddView else { return }
          
          if let node = view.relationshipWithName("promotion") as? OddRelationshipNode {
            if let promo = node.relationship as? OddRelationship {
              XCTAssertNotNil(promo, "View should have a relationship for promotion")
              XCTAssertEqual(promo.id, "daily-show", "View should have promotion relationship with correct id")
              XCTAssertEqual(promo.mediaObjectType.toString(), "promotion", "View should have promotion relationship with correct type")
            }
          }

          if let node = view.relationshipWithName("featuredMedia") as? OddRelationshipNode {
            if let featuredMedia = node.relationship as? OddRelationship {
              XCTAssertNotNil(featuredMedia, "View should have a relationship for featuredMedia")
              XCTAssertEqual(featuredMedia.id, "0db5528d4c3c7ae4d5f24cce1c9fae51", "View should have featuredMedia relationship with correct id")
              XCTAssertEqual(featuredMedia.mediaObjectType.toString(), "video", "View should have featuredMedia relationship with correct type")
            }
          }

          if let node = view.relationshipWithName("featuredCollections") as? OddRelationshipNode {
            XCTAssertNil(node.multiple, "View should only have singular relationships" )
            if let featuredCollections = node.relationship as? OddRelationship {
              XCTAssertNotNil(featuredCollections, "View should have a relationship for featuredCollections")
              XCTAssertEqual(featuredCollections.id, "ab2d92ee98b6309299e92024a487d4c0", "View should have featuredCollections relationship with correct id")
              XCTAssertEqual(featuredCollections.mediaObjectType.toString(), "collection", "View should have featuredCollections relationship with correct type")
            }
          }

          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectationsWithTimeout(10, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testCollectionsHaveCorrectRelationships() {
    let okExpectation = expectationWithDescription("ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let collectionId = "ab2d92ee98b6309299e92024a487d4c0"
        OddContentStore.sharedStore.objectsOfType(.Collection, ids: [collectionId], include: "entities", callback: { (objects, errors) in
          guard let collection = objects.first as? OddMediaObjectCollection else { return }
          
          if let node = collection.relationshipWithName("entities") as? OddRelationshipNode {
            if let videos = node.relationship as? Array<OddRelationship> {
              XCTAssertEqual(videos.count, 6, "Collection relationship should have an array of entities")
              XCTAssertEqual(videos.first?.id, "b99ab89d33c654277b739dadc53a2822", "Collection should have to correct related entities")
              XCTAssertEqual(videos.last?.id, "943af21ce037461b77c1752073c0a2a1", "Collection should have to correct related entities")
            }
          }
          
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectationsWithTimeout(10, handler: { error in
    XCTAssertNil(error, "Error")
    })
  }
  
  func testContentStoreLaunchesWithEmptyCache() {
    let okExpectation = expectationWithDescription("ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 0, "Upon launch content store should have an empty media object cache")
        
        okExpectation.fulfill()
      }
    }
    
    waitForExpectationsWithTimeout(10, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  
  func testFetchedObjectIsAddedToCache() {
    let okExpectation = expectationWithDescription("ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 0, "Upon launch content store should have an empty media object cache")
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        OddContentStore.sharedStore.objectsOfType(.View, ids: [homeViewId], include: nil, callback: { (objects, errors) in
          guard let view = objects.first as? OddView,
            let cachedView = OddContentStore.sharedStore.mediaObjects.first as? OddView else { return }
          
          XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 1, "After fetching a media object it is added to the content store cache")
          XCTAssertEqual(view.id, cachedView.id, "After fetching a media object the correct object is in the content store cache")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectationsWithTimeout(10, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testSearchReturnsResults() {
    let okExpectation = expectationWithDescription("ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        OddContentStore.sharedStore.searchForTerm("space", onResults: { (videos, collections) in
          
          XCTAssertEqual(videos?.count, 11, "Search should return the correct number of video results")
          XCTAssertEqual(collections?.count, 7, "Search should return the correct number of video results")
          
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectationsWithTimeout(10, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testSearchResultsAreAddedToStoreCache() {
    let okExpectation = expectationWithDescription("ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        OddContentStore.sharedStore.searchForTerm("space", onResults: { (videos, collections) in
          
          XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 18, "Search should return the correct number of video results")
          
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectationsWithTimeout(10, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testLocatesVideoWhenNotCached() {
    let okExpectation = expectationWithDescription("ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let videoId = "42baaa6e1e9ce2bb6d96d53007656f02"
        OddContentStore.sharedStore.objectsOfType(.Video, ids: [videoId], include: nil, callback: { (objects, errors) in
          guard let video = objects.first as? OddVideo else { return }
          XCTAssertNotNil(video, "SDK should load a video")
          XCTAssertEqual(video.id, "42baaa6e1e9ce2bb6d96d53007656f02", "Loaded video should have correct id")
          XCTAssertEqual(video.title, "What's Up - April 2016", "Loaded video should have correct title")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectationsWithTimeout(10, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testLocatesVideoWhenCached() {
    let okExpectation = expectationWithDescription("ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let videoId = "42baaa6e1e9ce2bb6d96d53007656f02"
        OddContentStore.sharedStore.objectsOfType(.Video, ids: [videoId], include: nil, callback: { (objects, errors) in
          guard let video = objects.first as? OddVideo,
            let cachedVideo = OddContentStore.sharedStore.mediaObjects.first as? OddVideo else { return }
          XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 1, "Fetched Video should be cached")
          XCTAssertEqual(video.id, cachedVideo.id, "The correct video should be cached")
          
          // now fetch again
          OddContentStore.sharedStore.objectsOfType(.Video, ids: [videoId], include: nil, callback: { (objects, errors) in
            guard let video = objects.first as? OddVideo else { return }
            XCTAssertEqual(objects.count, 1, "Fetching from cache returns the correct number of objects")
            XCTAssertEqual(video.id, cachedVideo.id, "Fetching from cache returns the correct video")
            okExpectation.fulfill()
          })
        })
      }
    }
    
    waitForExpectationsWithTimeout(10, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }

  
}
