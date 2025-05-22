//
//  WellingApp.swift
//  Welling
//
//  Created by Irwin Billing on 2024-05-10.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import FacebookCore
import AppTrackingTransparency
import Nuke
import FirebaseAppCheck
import SuperwallKit
import Mixpanel
import FirebaseCrashlytics
import FirebaseMessaging

@main
struct WellingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate, MessagingDelegate {
    let gcmMessageIDKey = "gcm.message_id"

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        let providerFactory = WellingAppCheckProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)
        
        FirebaseApp.configure()
        if (!UserDefaults.standard.bool(forKey: "notFirstRun")) {
            UserDefaults.standard.set(true, forKey: "notFirstRun")
            UserDefaults.standard.synchronize()
            do {
                let auth = Auth.auth()
                if let currentUser = auth.currentUser {
                    WLogger.shared.log("AppDelegate", "Signing out because this is first run.")
                    try auth.signOut()
                }
            } catch {
                WLogger.shared.record(error)
            }
        }
        
        let isTestFlight: Bool = BuildEnvironment.isSimulatorOrTestFlight()
        let projectToken: String = isTestFlight ? "660cea49b102ce9435bf9aeb211766a6" : "a592dd6920abf517f0659686ac75d6a3"
        Mixpanel.initialize(token: projectToken, trackAutomaticEvents: false)

        let superwallKey: String = isTestFlight ? "pk_bf199c848db9f406b4a74615b23739522e4d7d705ed1e697" : "pk_514f4f81246a8604d44cefea4d717478d58aead0c7f69046"
        Superwall.configure(apiKey: superwallKey)
        
        Crashlytics.crashlytics().setCustomValue(!isTestFlight, forKey: "isProduction")
        
        // Push notifications setup
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = NotificationsDelegate.shared
        application.registerForRemoteNotifications()
        
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        
//        let testAction = UNNotificationAction(identifier: "TEST_DISMISS", title: "")
//        let testCategory = UNNotificationCategory(identifier: "TEST_DISMISS", actions: [], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
//        
//        UNUserNotificationCenter.current().setNotificationCategories([testCategory])
        
        // Nuke Image pipeline configs
        ImagePipeline.shared = ImagePipeline(configuration: .withDataCache)
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Pass device token to auth
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification notification: [AnyHashable: Any]) async
    -> UIBackgroundFetchResult {
        print("Received notification while app was in background")
        
        if Auth.auth().canHandleNotification(notification) {
            return .noData
          }
        
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print full message.
        
        return UIBackgroundFetchResult.newData
    }
    

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: .fcmToken,
            object: nil,
            userInfo: dataDict
        )
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        var handled: Bool
        
        handled = Auth.auth().canHandle(url)
        if handled {
            return true
        }
        
        if Superwall.shared.handleDeepLink(url) {
            return true
        }
        
        handled = ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation])
        if handled {
            return true
        }
        
        handled = GIDSignIn.sharedInstance.handle(url)
        if handled {
            return true
        }
        
        return false
    }
}
