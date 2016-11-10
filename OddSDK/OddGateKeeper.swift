//
//  OddGateKeeper.swift
//  OddSDK
//
//  Created by Patrick McConnell on 1/19/16.
//  Copyright © 2016 Odd Networks, LLC. All rights reserved.
//

import UIKit

/// Options for Authorization Status
///
///
public enum AuthenticationStatus: String {
//  case Inactive = "inactive"                // this application is not using authentication/authorization
  case Uninitialized = "uninitialized"      // the auth process has not been completed
  case Initialized = "initialized"          // the auth process started but failed to complete
  case Authorized = "authorized"            // the user is authorized
}

class AuthenticationCredentials: NSObject, NSCoding {
  
  var url: String? = nil
  var userCode: String? = nil
  var deviceToken: String? = nil
  var state: AuthenticationStatus = .Uninitialized
  var accessToken : String? = nil
  var entitlementCredentials: jsonObject? = nil
  
  override var description : String {
    return "URL: \(url)\n User Code: \(userCode)\n Device Token: \(deviceToken)\n State: \(state.rawValue)\n Access Token: \(accessToken)\n Creds: \(entitlementCredentials)"
  }
  
  class func emptyCredentials() -> AuthenticationCredentials {
    return AuthenticationCredentials(
      url: nil,
      userCode : nil,
      deviceToken: nil,
      state: .Uninitialized,
      accessToken: nil,
      entitlementCredentials: nil
    )
  }
  
  class func activeCredentials() -> AuthenticationCredentials {
    if let credentialData: Data = Keychain.dataForAccount(OddConstants.kAuthenticationCredentialsAccountName) {
      guard let creds: AuthenticationCredentials = NSKeyedUnarchiver.unarchiveObject( with: credentialData ) as? AuthenticationCredentials else {
        return AuthenticationCredentials.emptyCredentials()
      }
      return creds
    } else {
      return AuthenticationCredentials.emptyCredentials()
    }
  }
  
  init( url: String?, userCode: String?, deviceToken: String?, state: AuthenticationStatus, accessToken: String?, entitlementCredentials : jsonObject?) {
    self.url = url
    self.userCode = userCode
    self.deviceToken = deviceToken
    self.state = state
    self.accessToken = accessToken
    self.entitlementCredentials = entitlementCredentials
  }

// removed for now. Auth -> Enabled in the config now means the entire app is paywalled
//  class func credentialsFromJson(json: jsonObject) {
//    if let enabled = json["enabled"] as? Bool {
//      if enabled && AuthenticationCredentials.activeCredentials().state == .Inactive {
//        AuthenticationCredentials(
//          url: nil,
//          userCode: nil,
//          deviceToken: nil,
//          state: .Uninitialized,
//          authenticationToken: nil
//        ).save()
//      } else if !enabled  {
//        AuthenticationCredentials(
//          url: nil,
//          userCode: nil,
//          deviceToken: nil,
//          state: .Inactive,
//          authenticationToken: nil
//        ).save()
//      }
//    }
//  }

  required convenience init?(coder decoder: NSCoder) {
    guard let url = decoder.decodeObject(forKey: OddConstants.kAuthenticationCredentialsURLKey) as? String?,
    let userCode = decoder.decodeObject(forKey: OddConstants.kAuthenticationCredentialsUserCodeKey) as? String?,
    let deviceToken = decoder.decodeObject(forKey: OddConstants.kAuthenticationCredentialsDeviceTokenKey) as? String?,
    let stateString = decoder.decodeObject(forKey: OddConstants.kAuthenticationCredentialsStateKey) as? String,
    let state: AuthenticationStatus = AuthenticationStatus( rawValue: stateString ),
    let accessToken = decoder.decodeObject(forKey: OddConstants.kAuthenticationCredentialsAccessTokenKey) as? String?,
    let entitlementCredentials = decoder.decodeObject(forKey: OddConstants.kAuthenticationCredentialsEntitlementCredentialsKey) as? jsonObject else { return nil }
    
    self.init(
      url: url,
      userCode : userCode,
      deviceToken: deviceToken,
      state: state,
      accessToken: accessToken,
      entitlementCredentials: entitlementCredentials
    )
  }
  
  func encode(with coder: NSCoder) {
    coder.encode(self.url, forKey: OddConstants.kAuthenticationCredentialsURLKey)
    coder.encode(self.userCode, forKey: OddConstants.kAuthenticationCredentialsUserCodeKey)
    coder.encode(self.deviceToken, forKey: OddConstants.kAuthenticationCredentialsDeviceTokenKey)
    coder.encode(self.state.rawValue, forKey: OddConstants.kAuthenticationCredentialsStateKey)
    coder.encode(self.entitlementCredentials, forKey: OddConstants.kAuthenticationCredentialsEntitlementCredentialsKey)
    coder.encode(self.accessToken, forKey: OddConstants.kAuthenticationCredentialsAccessTokenKey)
  }

  func save() {
    let encodedcredentials = NSKeyedArchiver.archivedData(withRootObject: self)
    Keychain.setData(encodedcredentials, forAccount: OddConstants.kAuthenticationCredentialsAccountName, synchronizable: true, background: false)
  }
  
  func updateAuthenticationCredentials(_ url: String?, userCode: String?, deviceToken: String?, state: AuthenticationStatus?, accessToken: String?, entitlementCredentials: jsonObject?) {
    
      if let url = url {
        self.url = url
      }
  
      if let userCode = userCode {
        self.userCode = userCode
      }
  
      if let deviceToken = deviceToken {
        self.deviceToken = deviceToken
      }
  
      if let state = state {
        self.state = state
      }
  
      if let accessToken = accessToken {
        self.accessToken = accessToken
      }
    
      if let entitlementCredentials = entitlementCredentials {
        self.entitlementCredentials = entitlementCredentials
      }
      
      self.save()
    }
  
}


public class OddGateKeeper: NSObject {
  
  /// A singleton instance of the `GateKeeper` class
  /// All access to the users authentication credentials should be made
  /// through this singleton instance
  static public let sharedKeeper = OddGateKeeper()
  
  // The current user/device `AuthenticationCredentials`
  lazy var authenticationCredentials = AuthenticationCredentials.activeCredentials()
  
  /// The amount of times between requesting the Authentication status from the server
  ///
  /// When a user attempts to link a device they are directed to a web site in order
  /// to connect their device to their account on the clients platform. The SDK will
  /// poll the API for updates in the user/devices Authentication state.
  var authAttemptTimeDelta: TimeInterval = 5  // check for Authentication every 5 seconds
  
  /// Number of times the server will be contacted to check for Authentication status changes.
  /// This number multiplied by `authAttemptTimeDelta` will determine how long the SDK will
  /// attempt to detecet a change in state before stopping.
  var numberOfAuthAttempts: Int = 60            // number of times to try before failing
  
  /// A counter to track the number of attempts we have made to check auth state changes
  var authAttemptCount = 0
  
  /// A timer to trigger Authentication state change checks
  var pollingTimer: Timer?
  
  /// The device token for this user/device
  var deviceToken: String?
  
  /// The user/device Authentication Status
  public var authenticationStatus: AuthenticationStatus {
    get {
      return self.authenticationCredentials.state
    }
  }
  
  public func fetchAuthenticationConfig( _ callback: @escaping (_ url: String?, _ userCode: String?, _ deviceToken: String?, _ error: NSError?) -> Void ) {
    OddContentStore.sharedStore.API.post(nil, url: "auth/device/code") { (res, err) -> () in
      if let e = err {
        OddLogger.error("Error fetching auth config: \(e)")
        callback(nil, nil, nil, e)
      } else {
        if let json = res as? Dictionary<String, AnyObject> {
          OddLogger.info("Auth Config: \(json)")
          
          guard let data = json["data"] as? jsonObject,
            let attribs = data["attributes"] as? jsonObject,
            let url = attribs["verification_url"] as? String,
            let deviceToken = attribs["device_code"] as? String,
            let userCode = attribs["user_code"] as? String else {
              let error = NSError(domain: "Odd", code: 100, userInfo: ["error" : "Unable to decode response"])
              callback(nil, nil, nil, error)
              return
          }
          
         // if let data = json["data"] as? jsonObject,
           // let attribs = data["attributes"] as? jsonObject{
//            if let url = attribs["verification_url"] as String,
//              let deviceToken: String? = data["attributes"]?["device_code"] as String,
//              let userCode: String? = data["attributes"]?["user_code"] as String {
                
          self.authenticationCredentials.updateAuthenticationCredentials( url,
                                                                     userCode: userCode,
                                                                  deviceToken: deviceToken,
                                                                        state: .Initialized,
                                                                  accessToken: nil,
                                                       entitlementCredentials: nil )
            
          callback(url, userCode, deviceToken, nil)
        }
      }
    }
  }
  
  public func blowAwayCredentials() {
    self.authenticationCredentials.updateAuthenticationCredentials( nil,
      userCode: nil,
      deviceToken: nil,
      state: .Uninitialized,
      accessToken: nil,
      entitlementCredentials: nil
    )
  }
  
  
  public func fetchAuthenticationToken() {
    print("checking for Authentication")
  
    guard let deviceToken = self.authenticationCredentials.deviceToken else { return }
    
    print("checking token: \(deviceToken)")
    
    let currentAuthenticationState = self.authenticationStatus
    
    OddContentStore.sharedStore.API.post(["type":"authorized_user" as AnyObject,"attributes":["device_code":"\(deviceToken)"] as AnyObject], url:"auth/device/token") { (res, err) -> () in
      if let error = err,
        let response = res {
        print("Error:\(error.localizedDescription)")
        if response.statusCode == 401 {
          self.authenticationCredentials.updateAuthenticationCredentials( nil,
            userCode: nil,
            deviceToken: nil,
            state: .Uninitialized,
            accessToken: nil,
            entitlementCredentials: nil
          )
        } else {
          NotificationCenter.default.post(name: OddConstants.OddAuthenticationErrorCheckingStateNotification, object: self.authenticationCredentials, userInfo: nil)
        }
      } else {
        guard let json = res as? jsonObject,
          let data = json["data"] as? jsonObject,
          let attribs = data["attributes"] as? jsonObject,
          let accessToken = attribs["access_token"] as? String,
          let userProfile = attribs["deviceUserProfile"] else { return }
        
        let creds = userProfile["entitlementCredentials"] as? jsonObject
        
        print("AUTH DATA: \(data)")
        self.authenticationCredentials.updateAuthenticationCredentials( nil,
          userCode: nil,
          deviceToken: deviceToken,
          state: .Authorized,
          accessToken: accessToken,
          entitlementCredentials: creds
        )
        /* debugging only
        print(json)
        print("Auth status changed")
        */
        if currentAuthenticationState != .Authorized {
          NotificationCenter.default.post(name: OddConstants.OddAuthenticationStateChangedNotification, object: self.authenticationCredentials, userInfo: nil)
        }
        self.pollingTimer?.invalidate()
      }
    }
  }
  
  func checkForAuthentication() {
    if authAttemptCount < numberOfAuthAttempts {
      authAttemptCount += 1
      print("Checking for change in auth status: \(authAttemptCount)")
      fetchAuthenticationToken()
    } else {
      print("Stopping check for change in auth status")
      pollingTimer?.invalidate()
    }
  }
  
  public func pollForAuthentication() {
    print("Starting polling timer")
    authAttemptCount = 0
    pollingTimer?.invalidate()
    // timer must be configured on the main thread or it will not fire
    DispatchQueue.main.async(execute: { () -> Void in
      self.pollingTimer = Timer.scheduledTimer(timeInterval: self.authAttemptTimeDelta, target: self, selector: #selector(OddGateKeeper.checkForAuthentication), userInfo: nil, repeats: true)
    })
    print("Timer started")
  }
  
  public func userIsAuthenticated() -> Bool {
    return OddGateKeeper.sharedKeeper.authenticationStatus == .Authorized
  }
  
  public func authTokenPresent() -> Bool {
    return UserDefaults.standard.string(forKey: OddConstants.kUserAuthenticationTokenKey) != nil
  }
  
  /// Convenience method to retun all keys in the
  /// entitlements credentials dictionary
  public func entitlementKeys() -> Set<String>? {
    var result = Set<String>()
    if let meta = OddGateKeeper.sharedKeeper.authenticationCredentials.entitlementCredentials {
      meta.keys.forEach({ (key) -> () in
        result.insert(key)
      })
      return result
    }
    return nil
  }
  
  /// Convenience method to return a given keys value
  /// or nil if it is not found
  public func valueForEntitlementKey(_ key: String) -> AnyObject? {
    if let keys = entitlementKeys() {
      if keys.contains(key) {
        return OddGateKeeper.sharedKeeper.authenticationCredentials.entitlementCredentials![key]!
      }
    }
    return nil
  }
  
  public func entitlementCredentials() -> jsonObject? {
    guard let creds = OddGateKeeper.sharedKeeper.authenticationCredentials.entitlementCredentials else { return nil }
    return creds
  }

  public func updateEntitlementCredentials(_ creds: jsonObject) {
    self.authenticationCredentials.updateAuthenticationCredentials( nil,
      userCode: nil,
      deviceToken: nil,
      state: nil,
      accessToken: nil,
      entitlementCredentials: creds
    )
  }
  
  func clearUserInfo() {
    OddLogger.info("Deleting User Info")
    UserDefaults.standard.set(nil, forKey: OddConstants.kUserAuthenticationTokenKey)
    UserDefaults.standard.set(nil, forKey: OddConstants.kUserIdKey)
    UserDefaults.standard.synchronize()
  }
  
  func parseUserInfoFromJson(_ json: jsonObject) -> Bool {
    guard let id = json["id"] as? String,
      let attribs = json["attributes"] as? jsonObject,
      let jwt = attribs["jwt"] as? String else {
      return false
    }
    UserDefaults.standard.set(jwt, forKey: OddConstants.kUserAuthenticationTokenKey)
    UserDefaults.standard.set(id, forKey: OddConstants.kUserIdKey)
    UserDefaults.standard.synchronize()
    return true
  }

  
  public func login (email: String, password: String, callback: @escaping (Bool) -> () ) {
    
    let params = [
      "data": [
        "type": "authentication",
        "attributes": [
          "email": email,
          "password": password
        ]
      ]
    ]
    
    OddContentStore.sharedStore.API.post(params as [String : AnyObject]?, url: "login") { (response, error) -> () in
      if error != nil {
        OddLogger.error("Error logging in")
        callback(false)
      } else {
        guard let json = response as? jsonObject,
          let data = json["data"] as? jsonObject else {
            OddLogger.error("Unable to parse login response")
            callback(false)
            return
        }
        let success = self.parseUserInfoFromJson(data)
        callback(success)
      }
    }
  }
  
}
