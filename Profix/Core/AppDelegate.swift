//
//  AppDelegate.swift
//  Profix
//
//  Created by Haneen on 03/12/2025.
//

import UIKit
import GoogleMaps
import IQKeyboardManagerSwift
import IQKeyboardToolbarManager
import FirebaseCore
import FirebaseMessaging
import AppsFlyerLib
import Clarity

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    //MARK: - Properties -
    
    let gcmMessageIDKey = "gcm.message_id"
    let googleMapKey = UserDefaults.googleMapKey
    
    //MARK: - Initializer -
    
    override init() {
        super.init()
        UIFont.overrideInitialize()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        self.handleKeyboard()
        
        self.handleGoogleMap()
        
        self.handleFCMFor(application)

        let clarityConfig = ClarityConfig(projectId: "ywin1s1s3s")
#if DEBUG
        clarityConfig.logLevel = .verbose
#endif
        ClaritySDK.initialize(config: clarityConfig)
        
        //AppsFlyer Configuration
#if DEBUG
        AppsFlyerLib.shared().isDebug = true
        print("[AppsFlyer] Configuring SDK")
#endif
        AppsFlyerLib.shared().initialize(
            devKey: "9kVNgq6RuG8MFbVBpBZeM",
            appId: AppStoreConstants.userAppID
        )
        
        AppsFlyerLib.shared().registerSessionReadyListener {
#if DEBUG
            print("[AppsFlyer] Session is ready; starting SDK")
#endif
            AppsFlyerLib.shared().start(completionHandler: { _, error in
#if DEBUG
                if let error {
                    print("[AppsFlyer] SDK start failed: \(error.localizedDescription)")
                } else {
                    print("[AppsFlyer] SDK started successfully")
                }
#endif
            })
        }
        
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    //MARK: - Google Maps -
    
    private func handleGoogleMap() {
        GMSServices.provideAPIKey("AIzaSyA73NKdDrPFoB-f3THMuoYBoPknWEYi8ho")
    }
    
    //MARK: - Keyboard -
    
    private func handleKeyboard() {
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardToolbarManager.shared.isEnabled = true
        IQKeyboardToolbarManager.shared.toolbarConfiguration.tintColor = UIColor(resource: .main)
        IQKeyboardManager.shared.disabledDistanceHandlingClasses = [ChatVC.self]
        IQKeyboardToolbarManager.shared.disabledToolbarClasses = [ChatVC.self]
    }
    
    
    //    //MARK: - FCM -
    private func handleFCMFor(_ application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
    }
}
