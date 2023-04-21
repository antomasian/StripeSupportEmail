import SwiftUI
import Firebase
import GoogleSignIn
import FBSDKCoreKit
import FacebookCore
import FirebaseMessaging
import UserNotifications
import os
import StripeApplePay

let BUNDLE_ID = "com.example.apple-samplecode.Tango"

@main
struct TangoApp: App {
    @StateObject var userVM: UserViewModel = UserViewModel()
    @StateObject var chatsListVM: ChatsListViewModel = ChatsListViewModel()
    @StateObject var eventsListVM: EventsListViewModel = EventsListViewModel()
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userVM)
                .environmentObject(chatsListVM)
                .environmentObject(eventsListVM)
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    let logger = Logger(subsystem: BUNDLE_ID, category: "AppDelegate")
    var dataDict: [String: String] = [:]
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions)

        FirebaseApp.configure()

        StripeAPI.defaultPublishableKey = "pk_test_51L8OqMKqX3ffZbB9VYc0i3OHZZ4iOQgGGcwkSbNHlRWl1QEvc5zIAouQfkepZr1tmjRtox4XqS4EStNhjDd9G2HZ00aLLRVLPD"
            
        // setting up cloud messaging
        Messaging.messaging().delegate = self
        
        // setting up notifications
        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
          UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
          )} else {
          let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
          application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
        
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        let deviceTokenString = deviceToken.map { String(format: "%02x", $0) }.joined()
        self.logger.info("Device token: \(deviceTokenString)")
        dataDict["deviceToken"] = deviceTokenString
    }

    func application(
            _ app: UIApplication,
            open url: URL,
            options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }
    
}

extension AppDelegate: MessagingDelegate {
    // Note: This callback is fired at each app startup and whenever a new token is generated.
    public func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        let logger = Logger(subsystem: BUNDLE_ID, category: "MessagingDelegate")
        logger.info("Received Firebase registration token: \(String(describing: fcmToken))")
        
        dataDict["token"] = fcmToken
        
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}
