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
// 
// specifically https://github.com/oddnetworks/oddworks/commit/33d14cbd5da6ae8c63ab86332262a8c22a2046d7
// is required to fix prior issues with included objects in api requests
// this commit will also include updated test data
//

import XCTest
@testable import OddSDK

protocol Idable {
  var id: String? { get set }
}

extension Set where Element : Idable {
  func containsObjectWithId(_ id: String) -> Bool {
    var result = false
    for (entity) in self {
      if let entityId = entity.id {
        if entityId == id {
          result = true
          break
        }
      }
    }
    return result
  }
}

extension OddMediaObject : Idable {}

class OddSDKTests: XCTestCase {
  
  let EXPECTATION_WAIT : TimeInterval = 20
  
  func configureSDK() {
    OddContentStore.sharedStore.API.serverMode = .test
    
    OddLogger.logLevel = .info
    
    /*
     If you are running your own Oddworks server the server will provide tokens for each channel
     and device you have configured when it launches. Paste the apple-tv token below.
     
     If you are using an Oddworks hosted server the token will be provided for you.
     
     This line is required to allow access to the API. Once you have entered your authToken uncomment
     to continue
     */
//    OddContentStore.sharedStore.API.authToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjaGFubmVsIjoibmFzYSIsInBsYXRmb3JtIjoiYXBwbGUtaW9zIiwidXNlciI6ImFkNjI3MGVmLTVjYTUtNGMxOS1iNDU4LTkxYmFlOGU0OTAwYSIsImlhdCI6MTQ3MDc1OTc5NSwiYXVkIjpbInBsYXRmb3JtIl0sImlzcyI6InVybjpvZGR3b3JrcyJ9.llj5k4Y7t_6mihFdcXFlWqc-HWWNbrvEZ0l-nUFcR6E"
    OddContentStore.sharedStore.API.authToken="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjaGFubmVsIjoibmFzYSIsInBsYXRmb3JtIjoiYXBwbGUtaW9zIiwiYXVkIjpbInBsYXRmb3JtIl0sImlzcyI6InVybjpvZGR3b3JrcyJ9.FHZRkkkTJbRul-kFJ3tkp5ShNEMDdlHE-OJpbLWBPjQ"
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
  
  func clearAuthToken() {
    UserDefaults.standard.set(nil, forKey: OddConstants.kUserAuthenticationTokenKey)
  }
  
  
  func testCanFetchConfig() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config else { return }
        XCTAssertNotNil(config, "SDK should load config")
        XCTAssertEqual(config.viewNames()?.count, 3, "Config should have correct number of views")
        okExpectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
//  If the following test is run along with the other tests Xcode will report it failing while it
//  meets all the assertion checks. If you can figure it out you are way cooler than me.
//  It will pass if run alone. Technically it passes in the group but Xcode is Xcode so thats that
  func testConfigHasCorrectViews() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config else { print("#### NO CONFIG #####");return }
        XCTAssertEqual(config.viewNames()?.count, 3, "Config should have correct number of views")
        XCTAssertEqual(config.idForViewName("homepage"), "homepage", "Config should have the correct views")
        XCTAssertEqual(config.idForViewName("splash"), "splash", "Config should have the correct views")
        XCTAssertEqual(config.idForViewName("menu"), "menu", "Config should have the correct views")
        okExpectation.fulfill()
        print("!!!!!!!!!!!!!! CONFIG TEST VALID !!!!!!!!!!!!!!!!!!")
      } else {
        print("!!!!!!!!!!!!!! some error?? !!!!!!!!!!!!!!!!!!")
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      print("!!!!!!!!!!!!!! CONFIG TEST TIMEOUT?? !!!!!!!!!!!!!!!!!!")
      XCTAssertNil(error, "Error")
    })
  }
  
  func testCanLoadHomeView() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        OddContentStore.sharedStore.objectsOfType(.view, ids: [homeViewId], include: nil, callback: { (objects, errors) in
          guard let view = objects.first as? OddView else { return }
          XCTAssertNotNil(view, "SDK should load a view")
          XCTAssertEqual(view.id, "homepage", "Config should have correct home view id")
          XCTAssertEqual(view.title, "Nasa Sample Homepage", "Config should have correct home view title")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testViewHasCorrectRelationships() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        OddContentStore.sharedStore.objectsOfType(.view, ids: [homeViewId], include: nil, callback: { (objects, errors) in
          guard let view = objects.first as? OddView else { return }
          
          if let node = view.relationshipNodeWithName("promotion") {
            XCTAssertEqual(node.numberOfRelationships, 1, "View should have the correct number of relationships")
            XCTAssertEqual(node.allIds!.count, 1, "Views relationship nodes should return the correct number of ids")
            if let promo = node.relationship as? OddRelationship {
              XCTAssertNotNil(promo, "View should have a relationship for promotion")
              XCTAssertEqual(promo.id, "daily-show", "View should have promotion relationship with correct id")
              XCTAssertEqual(promo.mediaObjectType.toString(), "promotion", "View should have promotion relationship with correct type")

            }
          }

          if let node = view.relationshipNodeWithName("featuredMedia") {
            XCTAssertEqual(node.numberOfRelationships, 1, "View should have the correct number of relationships")
            XCTAssertEqual(node.allIds!.count, 1, "Views relationship nodes should return the correct number of ids")
            if let featuredMedia = node.relationship as? OddRelationship {
              XCTAssertNotNil(featuredMedia, "View should have a relationship for featuredMedia")
              XCTAssertEqual(featuredMedia.id, "0db5528d4c3c7ae4d5f24cce1c9fae51", "View should have featuredMedia relationship with correct id")
              XCTAssertEqual(featuredMedia.mediaObjectType.toString(), "video", "View should have featuredMedia relationship with correct type")
            }
          }

          if let node = view.relationshipNodeWithName("featuredCollections") {
            XCTAssertEqual(node.numberOfRelationships, 1, "View should have the correct number of relationships")
            XCTAssertEqual(node.allIds!.count, 1, "Views relationship nodes should return the correct number of ids")
            XCTAssertNil(node.multiple, "View should only have singular relationships" )
            if let featuredCollections = node.relationship as? OddRelationship {
              XCTAssertNotNil(featuredCollections, "View should have a relationship for featuredCollections")
              XCTAssertEqual(featuredCollections.id, "nasa-featured-collections", "View should have featuredCollections relationship with correct id")
              XCTAssertEqual(featuredCollections.mediaObjectType.toString(), "collection", "View should have featuredCollections relationship with correct type")
            }
          }

          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }

  
  
  func testViewFetchesIncludedObjects() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        OddContentStore.sharedStore.objectsOfType(.view, ids: [homeViewId], include: "featuredMedia,featuredCollections", callback: { (objects, errors) in
          
          let cache = OddContentStore.sharedStore.mediaObjects
          XCTAssertEqual(cache.count, 3, "Loading a view should build included objects")
          
          XCTAssertTrue(cache.containsObjectWithId("homepage"), "Lodaing a view should build the view and included objects")
          XCTAssertTrue(cache.containsObjectWithId("0db5528d4c3c7ae4d5f24cce1c9fae51"), "Lodaing a view should build the view and included objects")
          XCTAssertTrue(cache.containsObjectWithId("nasa-featured-collections"), "Lodaing a view should build the view and included objects")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }

  
  func testCollectionsHaveCorrectRelationships() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let collectionId = "ab2d92ee98b6309299e92024a487d4c0"
        OddContentStore.sharedStore.objectsOfType(.collection, ids: [collectionId], include: "entities", callback: { (objects, errors) in
          guard let collection = objects.first as? OddMediaObjectCollection else { return }
          
          if let node = collection.relationshipNodeWithName("entities") {
            XCTAssertEqual(node.numberOfRelationships, 6, "Collection should have the correct number of relationships")
            XCTAssertEqual(node.allIds!.count, 6, "Collections relationship node should return the correct number of ids")
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
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
    XCTAssertNil(error, "Error")
    })
  }
  
  func testCollectionsFetchIncludedObjects() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let collectionId = "ab2d92ee98b6309299e92024a487d4c0"
        OddContentStore.sharedStore.objectsOfType(.collection, ids: [collectionId], include: "entities", callback: { (objects, errors) in
          guard let collection = objects.first as? OddMediaObjectCollection else { return }
          
          let cache = OddContentStore.sharedStore.mediaObjects
          XCTAssertEqual(cache.count, 7, "Loading a collection should build included objects")
          
          XCTAssertTrue(cache.containsObjectWithId("ab2d92ee98b6309299e92024a487d4c0"), "Loading a view should build the view and included objects")
          guard let node = collection.relationshipNodeWithName("entities"),
            let entities = node.relationship as? Array<OddRelationship> else  { return }
          
          entities.forEach({ (mediaObject) in
            XCTAssertTrue(cache.containsObjectWithId(mediaObject.id), "Loading a view should build the view and included objects")
          })
          
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testContentStoreLaunchesWithEmptyCache() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 0, "Upon launch content store should have an empty media object cache")
        
        okExpectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  
  func testFetchedObjectIsAddedToCache() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 0, "Upon launch content store should have an empty media object cache")
        guard let config = OddContentStore.sharedStore.config,
          let homeViewId = config.idForViewName("homepage") else { return }
        OddContentStore.sharedStore.objectsOfType(.view, ids: [homeViewId], include: nil, callback: { (objects, errors) in
          guard let view = objects.first as? OddView,
            let cachedView = OddContentStore.sharedStore.mediaObjects.first as? OddView else { return }
          
          XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 1, "After fetching a media object it is added to the content store cache")
          XCTAssertEqual(view.id, cachedView.id, "After fetching a media object the correct object is in the content store cache")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testSearchReturnsResults() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        OddContentStore.sharedStore.searchForTerm("earth", onResults: { (videos, collections) in
          
          XCTAssertEqual(videos?.count, 4, "Search should return the correct number of video results")
          XCTAssertEqual(collections?.count, 1, "Search should return the correct number of collections results")
          
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testSearchResultsAreAddedToStoreCache() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        OddContentStore.sharedStore.searchForTerm("space", onResults: { (videos, collections) in
          
          XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 5, "Search should return the correct number of video results")
          
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testLocatesVideoWhenNotCached() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let videoId = "42baaa6e1e9ce2bb6d96d53007656f02"
        OddContentStore.sharedStore.objectsOfType(.video, ids: [videoId], include: nil, callback: { (objects, errors) in
          guard let video = objects.first as? OddVideo else { return }
          XCTAssertNotNil(video, "SDK should load a video")
          XCTAssertEqual(video.id, "42baaa6e1e9ce2bb6d96d53007656f02", "Loaded video should have correct id")
          XCTAssertEqual(video.title, "What's Up - April 2016", "Loaded video should have correct title")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testLocatesVideoWhenCached() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let videoId = "42baaa6e1e9ce2bb6d96d53007656f02"
        OddContentStore.sharedStore.objectsOfType(.video, ids: [videoId], include: nil, callback: { (objects, errors) in
          guard let video = objects.first as? OddVideo,
            let cachedVideo = OddContentStore.sharedStore.mediaObjects.first as? OddVideo else { return }
          XCTAssertEqual(OddContentStore.sharedStore.mediaObjects.count, 1, "Fetched Video should be cached")
          XCTAssertEqual(video.id, cachedVideo.id, "The correct video should be cached")
          
          // now fetch again
          OddContentStore.sharedStore.objectsOfType(.video, ids: [videoId], include: nil, callback: { (objects, errors) in
            guard let video = objects.first as? OddVideo else { return }
            XCTAssertEqual(objects.count, 1, "Fetching from cache returns the correct number of objects")
            XCTAssertEqual(video.id, cachedVideo.id, "Fetching from cache returns the correct video")
            okExpectation.fulfill()
          })
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testVideoHasCorrectData() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let videoId = "42baaa6e1e9ce2bb6d96d53007656f02"
        OddContentStore.sharedStore.objectsOfType(.video, ids: [videoId], include: nil, callback: { (objects, errors) in
          guard let video = objects.first as? OddVideo else { return }
          XCTAssertNotNil(video, "SDK should load a video")
          XCTAssertEqual(video.id, "42baaa6e1e9ce2bb6d96d53007656f02", "Video should have correct id")
          XCTAssertEqual(video.title, "What's Up - April 2016", "Video should have correct title")
          XCTAssertEqual(video.notes, "Jupiter, Mars, the Lyrid meteor shower and 2016's best views of Mercury.", "Video should have the correct description")
          XCTAssertEqual(video.sources?.count, 1, "Video should have the correct number of OddImage assets")
          XCTAssertEqual(video.sources?[0].url, "http://www.podtrac.com/pts/redirect.m4v/www.jpl.nasa.gov/videos/whatsup/20160401/JPL-20160401-WHATSUf-0001-720-CC.m4v", "OddSource asset should have a url" )
          XCTAssertEqual(video.sources?[0].label, "default", "OddSource asset should have a label")
          XCTAssertEqual(video.sources?[0].mimeType, "video/mp4", "OddSource asset should have a label")
          XCTAssertEqual(video.urlString, "http://www.podtrac.com/pts/redirect.m4v/www.jpl.nasa.gov/videos/whatsup/20160401/JPL-20160401-WHATSUf-0001-720-CC.m4v", "Video should have correct url")
          XCTAssertEqual(video.duration, 13000000, "Video should have correct duration")
          XCTAssertEqual(video.images?.count, 1, "Video should have the correct number of OddImage assets")
          XCTAssertEqual(video.images?[0].url, "http://image.oddworks.io/NASA/space4.jpeg", "OddImage asset should have a url" )
          XCTAssertEqual(video.images?[0].label, "thumbnail image", "OddImage asset should have a label")
          XCTAssertEqual(video.images?[0].mimeType, "image/jpeg", "OddImage asset should have a mimeType")
          XCTAssertEqual(video.thumbnailLink, "http://image.oddworks.io/NASA/space4.jpeg", "Video should have correct image link")
          XCTAssertNotNil(video.cacheTime, "Video should have a cacheTime value")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testFetchReturnsOnlyRequestedObjectTypesNoInclude() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let menuViewId = config.idForViewName("menu") else { return }
        OddContentStore.sharedStore.objectsOfType(.view, ids: [menuViewId], include: nil, callback: { (objects, errors) in
          guard let view = objects.first as? OddView,
            let node = view.relationshipNodeWithName("items"),
            let ids = node.allIds else { return }
          
          OddContentStore.sharedStore.objectsOfType(.collection, ids: ids, include: nil, callback: { (objects, errors) in
            XCTAssertEqual(objects.count, 1, "Fetch objects of type should only return the correct types")
            XCTAssertEqual(objects.first?.id, "ab2d92ee98b6309299e92024a487d4c0", "Fetch objects of type should only return the correct types")
            okExpectation.fulfill()
          })
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })

  }

  
  func testFetchReturnsOnlyRequestedObjectTypesWithInclude() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        guard let config = OddContentStore.sharedStore.config,
          let menuViewId = config.idForViewName("menu") else { return }
        OddContentStore.sharedStore.objectsOfType(.view, ids: [menuViewId], include: "items", callback: { (objects, errors) in
          guard let view = objects.first as? OddView,
            let node = view.relationshipNodeWithName("items"),
            let ids = node.allIds else { return }
          
          OddContentStore.sharedStore.objectsOfType(.collection, ids: ids, include: nil, callback: { (objects, errors) in
            XCTAssertEqual(objects.count, 1, "Fetch objects of type should only return the correct types")
            XCTAssertEqual(objects.first?.id, "ab2d92ee98b6309299e92024a487d4c0", "Fetch objects of type should only return the correct types")
            XCTAssertEqual(errors!.first?.userInfo["error"]! as? String, "0db5528d4c3c7ae4d5f24cce1c9fae51 exists but is not of type collection", "Fetch objects of type should return an error for mismatched types")
            okExpectation.fulfill()
          })
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
    
  }
  
  func testCanFetchNodeIdsOfType() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        OddContentStore.sharedStore.objectsOfType(.view, ids: ["menu"], include: "items", callback: { (objects, errors) in
          guard let view = objects.first as? OddView,
            let node = view.relationshipNodeWithName("items"),
            let ids = node.idsOfType(.video) else { return }
          XCTAssertEqual(ids.count, 1)
          XCTAssertEqual(ids[0], "0db5528d4c3c7ae4d5f24cce1c9fae51")
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testCanFetchObjectsInRelationship() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        OddContentStore.sharedStore.objectsOfType(.view, ids: ["menu"], include: "items", callback: { (objects, errors) in
          guard let view = objects.first as? OddView,
            let node = view.relationshipNodeWithName("items") else { return }
          node.getAllObjects({ (objects, errors) in
            XCTAssertEqual(objects.count, 2)
            XCTAssertEqual(objects.filter({$0.id == "0db5528d4c3c7ae4d5f24cce1c9fae51"}).count, 1)
            XCTAssertEqual(objects.filter({$0.id == "ab2d92ee98b6309299e92024a487d4c0"}).count, 1)
            okExpectation.fulfill()
          })
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
  
  func testGateKeeperAuthenticationStatusDefaultsToUninitialized() {
    let authState = OddGateKeeper.sharedKeeper.authenticationStatus
    
    XCTAssertEqual(authState, .Uninitialized, "Authentication State should default to Uninitialized")
  }
  
  func xtestGateKeeperEntitlementCredentialsNilByDefault() {
    OddGateKeeper.sharedKeeper.blowAwayCredentials()
    XCTAssertNil(OddGateKeeper.sharedKeeper.entitlementCredentials(), "Entitlement Credentials should be empty (nil) by default")
  }
  
  func testGateKeeperCanUpdateEntitlementCredentials() {
    
    OddGateKeeper.sharedKeeper.blowAwayCredentials()
    XCTAssertNil(OddGateKeeper.sharedKeeper.entitlementCredentials(), "Entitlement Credentials should be empty (nil) by default")
    
    let credentials: jsonObject = [ "foo" : "bar" as AnyObject ]
    OddGateKeeper.sharedKeeper.updateEntitlementCredentials(credentials)
    
    guard let currentCredentials = OddGateKeeper.sharedKeeper.entitlementCredentials() else {
      XCTAssert(true, "Entitlement Credentials should be present")
      return
    }
    
    XCTAssertEqual(credentials["foo"] as! String, currentCredentials["foo"] as! String , "Entitlement Credentials should update")
  }

  func testImageIsFetchedAndCached() {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.initialize { (success, error) in
      if success {
        let videoId = "42baaa6e1e9ce2bb6d96d53007656f02"
        OddContentStore.sharedStore.objectsOfType(.video, ids: [videoId], include: nil, callback: { (objects, errors) in
          guard let video = objects.first as? OddVideo,
            let imageObject = video.images?.first else { return }
          
          imageObject.image({ (image) in
            XCTAssertNil(image, "OddImage should fetch image")
            let cachedImage = OddContentStore.sharedStore.imageCache.object(forKey: imageObject.url as NSString )
            XCTAssertNil(cachedImage, "OddImage should cache image after fetching")
          })
          okExpectation.fulfill()
        })
      }
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
    })
  }
 
  func testLoginReturnsSuccess()  {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.login(email: "success@nasa.gov", password: "foobar") { (success) in
      if success {
        print("***** LOGIN SUCCESS *****")
      } else {
        print("***** LOGIN FAILURE *****")
      }
      XCTAssertTrue(success, "Login should succeed with valid credentials")
      okExpectation.fulfill()
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
      self.clearAuthToken()
    })

  }
  
  func testLoginFails()  {
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.login(email: "foo@bar.com", password: "foobar") { (success) in
      if success {
        print("***** LOGIN SUCCESS *****")
      } else {
        print("***** LOGIN FAILURE *****")
      }
      XCTAssertFalse(success, "Login should fail with invalid credentials")
      okExpectation.fulfill()
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
      self.clearAuthToken()
    })
    
  }
  
  func testAuthTokenCheckWorks()  {
    clearAuthToken()
    var tokenPresent = OddGateKeeper.sharedKeeper.authTokenPresent()
    XCTAssertFalse(tokenPresent, "Auth Token Should not be present until login")
    
    
    let okExpectation = expectation(description: "ok")
    
    OddContentStore.sharedStore.login(email: "success@nasa.gov", password: "foobar") { (success) in
      if success {
        print("***** LOGIN SUCCESS *****")
        UserDefaults.standard.set("somejwttokenvalue", forKey: OddConstants.kUserAuthenticationTokenKey)
        tokenPresent = OddGateKeeper.sharedKeeper.authTokenPresent()
        XCTAssertTrue(tokenPresent, "Auth Token Should be present after login")
      } else {
        print("***** LOGIN FAILURE *****")
        XCTAssert(false, "Auth Token Should be present after login")
      }
  
      okExpectation.fulfill()
    }
    
    waitForExpectations(timeout: EXPECTATION_WAIT, handler: { error in
      XCTAssertNil(error, "Error")
      self.clearAuthToken()
    })
    
    
  }
}
