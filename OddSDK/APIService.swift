//
//
//  APIService.swift
//
//  Created by Patrick McConnell on 7/31/15.
//  Copyright (c) 2015 Odd Networks, LLC. All rights reserved.
//

import UIKit

/// A helper object to provide either an object
/// or the error returned from the server
public typealias APICallback = ((AnyObject?, NSError?) -> Void)


/// A Struct to encapsulate various device information fields
///
/// No configuration of the Struct is required. All required information is
/// included by calling `constructHeader()`
struct UserAgentHeader {
  let deviceModel = UIDevice.current.model.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
  let deviceName = UIDevice.current.name.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
  let buildVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
  let osVersion = UIDevice.current.systemVersion.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
  let os = UIDevice.current.systemName.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)
  
  /// A helper method for `UserAgentHeader` to build the correct device information fields required
  /// to be provided with each request to the API server
  ///
  /// No parameters are required. All required information is automatically built and returned in the response.
  ///
  /// returns: A `string` containing the required device information
  func constructHeader() -> String {
    if let build = buildVersion,
      let encodedBuild = build.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed),
      let deviceModel = deviceModel,
      let deviceName = deviceName,
      let os = os,
      let osVersion = osVersion {
        let userAgentHeader = "platform[name]=\("Apple")&model[name]=\(deviceModel)&model[version]=\(deviceName)&model[brand]=\("Apple")&model[manufacturer]=\("Apple")&os[name]=\(os)&os[version]=\(osVersion)&buildVersion=\(encodedBuild)"
        return userAgentHeader
    } else {
      return "platform[name]=\("Apple")&model[name]=\("unknown")&model[version]=\("unknown")&os[name]=\("unknown")&model[brand]=\("Apple")&model[manufacturer]=\("Apple")&os[version]=\("unknown")&buildVersion=\("unknown")"
    }
  }
}


/// Handles http requests for the API server.
/// Parses reponses or errors returning the appropriate
/// `JSON` or server error information
public class APIService: NSObject {

  /// Only one instance of this class is required for any app.
  /// Access should be made through this singleton
  static let sharedService = APIService()
  
  /// The url string used by the APIService to contact the API server
  ///
  /// Should include the version and will default to the SaaS instance.
  public var apiEndpoint: String = "https://content.oddworks.io/v2/"
  
  /// The device/organization specific authorization token as provided by Odd
  /// must be set before the API can be accessed successfully.
  public var authToken: String = ""

  private var userAuthToken: String {
    get {
      let defaults = UserDefaults.standard
      guard let token = defaults.string(forKey: OddConstants.kUserAuthenticationTokenKey) else {
        return authToken
      }
      return token
    }
  }

  /// A `String` built from various device infomation fields to be sent to the API server
  /// with each request
  var agentHeader = UserAgentHeader()
  
  
  //MARK: INITIALIZERS
  
  /// Designated initializer
  ///
  /// No configurable options at this time
  override init() {
    super.init()
  }
    
  //MARK: Requests
  
  /// Performs a `GET` request on the API Server
  ///
  /// - parameter params: an optional `Dictionary` containing any parameters required for the request
  /// - parameter url: a `String` containing the route for the API method to be requested
  /// - parameter callbck: an `APICallback` that will either contain the json of the 
  /// requested object or an error if the request failed
  ///
  /// See also: `APICallback`
  public func get(_ params: [ String : AnyObject ]?, url: String, callback: @escaping APICallback) {
    request("GET", params: params, url: url, callback: callback)
  }
  
  /// Performs a `POST` request on the API Server
  ///
  /// - parameter params: an optional `Dictionary` containing any parameters required for the request
  /// - parameter url: a `String` containing the route for the API method to be requested
  /// - parameter callbck: an `APICallback` that will either contain the json of the
  /// requested object or an error if the request failed
  ///
  /// See also: `APICallback`
  public func post(_ params: [ String : AnyObject ]?, url: String, callback: @escaping APICallback) {
    request("POST", params: params, url: url, callback: callback)
  }
  
  /// Performs a `PUT` request on the API Server
  ///
  /// - parameter params: an optional `Dictionary` containing any parameters required for the request
  /// - parameter url: a `String` containing the route for the API method to be requested
  /// - parameter callbck: an `APICallback` that will either contain the json of the
  /// requested object or an error if the request failed
  ///
  /// See also: `APICallback`
  public func put(_ params: [ String : AnyObject ]?, url: String, callback: @escaping APICallback) {
    request("PUT", params: params, url: url, callback: callback)
  }
  
  /// Performs a `DELETE` request on the API Server
  ///
  /// - parameter params: an optional `Dictionary` containing any parameters required for the request
  /// - parameter url: a `String` containing the route for the API method to be requested
  /// - parameter callbck: an `APICallback` that will either contain the json of the
  /// requested object or an error if the request failed
  ///
  /// See also: `APICallback`
  public func delete(_ params: [ String : AnyObject ]?, url: String, callback: @escaping APICallback) {
    request("DELETE", params: params, url: url, callback: callback)
  }
  
  //MARK: Private Methods
  
  /// Decorates the http request with required headers, 
  /// attaches params and dispatches the request.
  /// 
  /// Once a response is received the returned response or error is parsed
  /// and returned via the callback
  /// 
  /// Note: This is a private method not available to client applications.
  /// In most cases this method will not need to be accessed directly and
  /// access should be through the get, post, put and delete methods
  ///
  /// - parameter type: The `string` for the request type (GET, POST, PUT or DELETE)
  /// - parameter params: An optional `Dictionary` containing any parameters required for the request
  /// - parameter url: a `String` containing the route for the API method to be requested
  /// - parameter callbck: an `APICallback` that will either contain the json of the
  /// requested object or an error if the request failed
  ///
  /// See also: `APICallback`, `get()`, `post()`, `put()`, 'delete()'
  private func request(_ type: String, params: [ String : AnyObject ]?, url: String, callback: @escaping APICallback) {
    let request = NSMutableURLRequest(url: URL(string: apiEndpoint + url)!)
    let session = URLSession.shared
    request.httpMethod = type
    
    let err: NSError?
    
    if let parameters = params {
      do {
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
      } catch let error as NSError {
        err = error
        request.httpBody = nil
        print("error attaching params: \(err?.localizedDescription)")
      }
    }
    
    
    //Build & App Specific Headers:
    request.addValue(agentHeader.constructHeader(), forHTTPHeaderField: "x-odd-user-agent")
    request.addValue("Bearer \(userAuthToken)", forHTTPHeaderField: "Authorization")
    //Utility Headers:
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    request.addValue(Locale.current.identifier, forHTTPHeaderField: "Accept-Language")
    
    
    
    #if os(tvOS)
      request.addValue("tvOS", forHTTPHeaderField: "User-Agent")
    #else
      if UIDevice.current.userInterfaceIdiom == .pad  {
        request.addValue("iPad", forHTTPHeaderField: "User-Agent")
      } else {
        request.addValue("iPhone", forHTTPHeaderField: "User-Agent")
      }
    #endif  
    
    let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error -> Void in
      
      if let e = error as? URLError {
        if e.code == .notConnectedToInternet {
          NotificationCenter.default.post(Notification(name: OddConstants.OddConnectionOfflineNotification, object: e) )
        }
        callback(nil, e as NSError?)
        return
      }
      
      //      let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)!
      //      println("JSON String: \(jsonStr)")
      //
      
      var cacheTime: Int?
      if let res = response as! HTTPURLResponse! {

        // headers are defined as [String : String] so...
        if let cacheStr = res.allHeaderFields["Cache-Control"] as? String {
          let cacheArray = cacheStr.components(separatedBy: ", ")
          let maxAge = cacheArray[1]
          let cache = maxAge.replacingOccurrences(of: "max-age=", with: "")
          cacheTime = Int(cache)
        }

        if res.statusCode == 401 { // unauthorized
          print("Error server responded with 401: Unauthorized to \(url) with \(self.authToken)")
//          OddGateKeeper.sharedKeeper.blowAwayCredentials()
          OddGateKeeper.sharedKeeper.clearUserInfo()
          NotificationCenter.default.post(Notification(name: NSNotification.Name("unauthorizedResponseReturned") , object: nil))
        }
        
        if res.statusCode == 201 {
          OddLogger.info("Server responded with \(res.statusCode). Object created.")
          callback(response, nil)
          return
        }
        
        // 202 is the correct response for add to watchlist
        if res.statusCode == 202 {
          OddLogger.info("Server responded with \(res.statusCode). Object created.")
          callback(response, nil)
          return
        }
        
        if res.statusCode != 200 {
          OddLogger.error("Error, server responded with: \(res.statusCode)" )
          var errorMessage = "No data returned"
          if let localData = data {
            errorMessage = self.parseError(localData)
          }
          let e = NSError(domain: "ODD", code: 100, userInfo: [ "statusCode": res.statusCode, "message" : errorMessage ])
          callback(nil, e)
          return
        }
      }
      
      if error == nil {
        self.parseData(data, cacheTime: cacheTime, callback: callback)
      }
    })
    
    task.resume()
  }
  
  
  /// Parses an error returned from the server.
  ///
  /// - parameter data: an `NSData` object containing the error returned from the server
  /// - returns: A `String` with the error if in the correct error message format or "undefined"
  ///
  /// Note: if the server returns an error message in the format "message" : <the error message>
  /// this method returns the message string otherwise "undefined"
  private func parseError(_ data: Data) -> String {
    //    let serializationError: NSError?
    //    let json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves) as? [ String:AnyObject ]
    //
    //
    var serializationError: NSError?
    var json: AnyObject?
    do {
      json = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as AnyObject
    } catch let error as NSError {
      serializationError = error
      json = nil
    }
    
    
    if(serializationError != nil) {
      return "undefined"
    } else {
      guard let json = json as? jsonObject,
        let errors = json["errors"] as? jsonArray,
        let firstError = errors.first,
        let error = firstError["detail"] as? String else {
          return "Unspecified error"
      }
      
      return error
    }
  }
  
  /// Parses the data returned from an http request
  ///
  /// - parameter data: An optional `NSData` object containing the server response, if any
  /// - parameter callbck: an `APICallback` that will either contain the json of the
  /// response or nil if no data is found or an error occurred serializing the response
  private func parseData(_ data: Data?, cacheTime: Int? = nil, callback: @escaping APICallback) {
    
    func reportJsonError() {
      print("Error could not parse JSON")
      let e = NSError(domain: "Oddworks", code: 101, userInfo: [ "JSON" : "No data found" ])
      callback(nil, e)
    }
    
    if data == nil {
      reportJsonError()
    } else {
      
      var serializationError: NSError?
      //    var json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &serializationError) as? [ String:AnyObject ]
      
      var json: AnyObject?
      do {
        json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as AnyObject
        
        if let cacheTime = cacheTime {
          let mutableDict = NSMutableDictionary(dictionary: (json as? NSDictionary)!)
          if let theData = mutableDict["data"] as? NSMutableDictionary {
              theData.setObject(cacheTime, forKey: "cacheTime" as NSCopying)
              json = mutableDict
          }
        }

      } catch let error as NSError {
        serializationError = error
        json = nil
      }
      
      //    if let response: AnyObject = json {
      //      if response.isKindOfClass(NSArray) {
      //        println("***** JSON ARRAY *****")
      //      } else {
      //        println("***** JSON DICTIONARY *****")
      //      }
      //    }
      
      if(serializationError != nil) {
        callback(nil, serializationError)
      }
      else {
        if let parsedJSON: AnyObject = json {
          callback(parsedJSON, nil)
        }
        else {
          reportJsonError()
        }
      }
    }
  }
  
}
