//
//  OddConstants.swift
//  OddSDK
//
//  Created by Patrick McConnell on 12/21/15.
//  Copyright © 2015 Odd Networks, LLC. All rights reserved.
//

import Foundation

/// A class to encapsulate common globally required values such as notification names
@objc public class OddConstants: NSObject {
    
    static let kKeychainServiceKey = "OddworksKeychainService"
    static let kAuthenticationCredentialsAccountName = "AuthenticationCredentialsAccountNameKey"
    static let kAuthenticationCredentialsURLKey = "AuthenticationCredentialsURLKey"
    static let kAuthenticationCredentialsUserCodeKey = "AuthenticationCredentialsUserCodeKey"
    static let kAuthenticationCredentialsDeviceTokenKey = "AuthenticationCredentialsDeviceTokenKey"
    static let kAuthenticationCredentialsStateKey = "AuthenticationCredentialsStateKey"
    static let kAuthenticationCredentialsAccessTokenKey = "AuthenticationCredentialsAccessTokenKey"
    static let kAuthenticationCredentialsEntitlementCredentialsKey = "AuthenticationCredentialsEntitlementCredentialsKey"
    
    static let kUserAuthenticationTokenKey = "UserAuthenticationTokenKey"
    static let kUserIdKey = "UserId"
    
    static let kOddLoginName = "OddLoginName"
    static let kOddLoginPassword = "OddLoginPassword"
    
    /// The notification posted by the `OddContentStore` when there is an error fetching the app config
    public static let OddErrorFetchingConfigNotification = Notification.Name("OddErrorFetchingConfigNotification")
    
    /// The notification posted by the `OddContentStore` when the `OddConfig` has been successfully fetched from the server
    public static let OddFetchedConfigNotification = Notification.Name("OddFetchedConfigNotification")
    
    /// The notification posted by the `OddContentStore` when there is an error fetching a view
    public static let OddErrorFetchingViewNotification = Notification.Name("OddErrorFetchingViewNotification")
    
    /// The notification posted by the `OddContentStore` when there is an error fetching the main/home view information
    public static let OddErrorFetchingHomeViewNotification = Notification.Name("OddErrorFetchingHomeViewNotification")
    
    /// The notification posted by the `OddContentStore` when there is an error fetching the menu view information
    public static let OddErrorFetchingMenuViewNotification = Notification.Name("OddErrorFetchingMenuViewNotification")
    
    /// The notification posted by the `OddContentStore` when it has completed loading and parsing all required data for the home view
    public static let OddContentStoreCompletedInitialLoadNotification = Notification.Name("OddContentStoreCompletedInitialLoadNotification")
    
    /// The notification posted by the `OddContentStore` after it has loaded the featured media object
    public static let OddFeaturedMediaObjectLoadedNotification = Notification.Name("OddFeaturedMediaObjectLoadedNotification")
    
    /// The notification posted by the `OddContentStore` after the featured collections have been loaded
    public static let OddFeaturedCollectionsLoadedNotification = Notification.Name("OddFeaturedCollectionsLoadedNotification")
    
    /// The notification posted by the `OddContentStore` after the featured promotion has been loaded
    public static let OddFeaturedPromotionLoadedNotification = Notification.Name("OddFeaturedPromotionLoadedNotification")
    
    /// The notification posted by the `OddContentStore` after the included entities for the menu have been loaded and parsed
    public static let OddIncludedMediaItemsLoadedNotification = Notification.Name("OddIncludedMediaItemsLoadedNotification")
    
    // The notification posted by the 'OddContentStore' when a search request is made to the API server
    public static let OddStartedSearchNotification = Notification.Name("OddStartedSearchNotification")
    
    // The notification posted by the 'OddContentStore' when a search request is complete
    public static let OddEndedSearchNotification = Notification.Name("OddEndedSearchNotification")
    
    // The notification posted by the 'OddContentStore' when a watchlist fetch request is made to the API server
    public static let OddStartedWatchlistFetchNotification = Notification.Name("OddStartedWatchlistFetchNotification")
    
    
    // The notification posted by the 'OddGateKeeper' when a users Authorization/Entitlement State has changed
    public static let OddAuthenticationStateChangedNotification = Notification.Name("OddAuthenticationStateChangedNotification")
    
    // The notification posted by the 'OddGateKeeper' if it receives an error (excluding 401) when checking for auth token
    public static let OddAuthenticationErrorCheckingStateNotification = Notification.Name("OddAuthenticationErrorCheckingStateNotification")
    
    // The notification posted by 'APIService' when they get an offline error
    public static let OddConnectionOfflineNotification = Notification.Name("OddConnectionOfflineNotification")
    
    // The notification posted by 'OddMediaObject' when an image doesn't load
    public static let OddImageLoadDidFail = Notification.Name("OddImageLoadDidFail")
    
    // The notification posted upon successfully updating the viewers watchlist
    public static let OddWatchlistUpdated = Notification.Name("OddWatchlistUpdated")
}
