//
//  AppDelegate.swift
//  Pointer
//
//  Created by Michael Biehl on 5/20/17.
//  Copyright © 2017 Pointer. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn
import UserNotifications
import FirebaseInstanceID
import FirebaseMessaging
import FBSDKCoreKit
import FBSDKLoginKit
import FBSDKShareKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?
    var notificationTarget: String?
    
    var viewController: WKWebViewController? {
        return window?.rootViewController as? WKWebViewController
    }
    
    internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        registerForNotifications(application)
        FirebaseApp.configure()
        
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        
        ApplicationDelegate.shared.application(application,
                                                              didFinishLaunchingWithOptions: launchOptions)
        
        guard let fcmToken = Messaging.messaging().fcmToken else { return true }
        print("======> FCM \(fcmToken)")

        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

//        let googHandled = GIDSignIn.sharedInstance().handle(url, options[UIApplication.OpenURLOptionsKey.sourceApplication] as String,
//                                                            annotation: options[UIApplication.OpenURLOptionsKey.annotation])

        if let googHandled = GIDSignIn.sharedInstance()?.handle(url) {
            return googHandled
        }

        let fbHandled = ApplicationDelegate.shared.application(app, open: url)

        return fbHandled
    }
        
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        if let googHandled = GIDSignIn.sharedInstance()?.handle(url) {
            return googHandled
        }
        
        let fbHandled = ApplicationDelegate.shared.application(
          application,
          open: url,
          sourceApplication: sourceApplication,
          annotation: annotation
        )
        
        return fbHandled
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            googSignInVC?.appDelegate(self,
                                      didFailToSignin: error)
            return
        }
        
        googSignInVC?.appDelegate(self,
                                  didSignUserIn: user)
        
        if GIDSignIn.sharedInstance()?.currentUser == nil {
        } else {
            let webViewVC = WKWebViewController()
            window?.rootViewController = UINavigationController(rootViewController: webViewVC)
            window?.makeKeyAndVisible()
        }
    }
    
    var googSignInVC: GoogleSignInViewController? {
        return window?.rootViewController as? GoogleSignInViewController
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func registerForNotifications(_ application: UIApplication) {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 data message (sent via FCM
            Messaging.messaging().delegate = self
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Error registering for remote notifications", error)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("DID REGISTERRRRRR")
        //TODO: send fcm token to surver here
    }
    
    func requestAuthorization(options: UNAuthorizationOptions = [],
                              completionHandler: @escaping (Bool, Error?) -> Void) {
        
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("WILL PRESENT???")
        completionHandler([.alert, .sound])
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("DID RECEIVE RESPONSE???")
        if let target = response.notification.request.content.userInfo["target"] as? String {
            viewController?.appDelegate(self,
            didReceiveRemoteNotification: PointerNotification(path: target))

        }
        
        completionHandler()
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("DID RECEIVE YO")
        completionHandler(.noData)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print("DID RECEIVE")
    }
    
    func application(received remoteMessage: MessagingRemoteMessage) {
        print("GOT A FIRE MESSAGE")
        print(remoteMessage)
        
//        if let path = userInfo["target"] as? String {
//            viewController?.appDelegate(self,
//                                        didReceiveRemoteNotification: PointerNotification(path: path))
//        }
    }
    
    func sendFCMToken(to url: URL!, pointerToken: String!) {
        var request = URLRequest(url: url)
        guard let fcmToken = Messaging.messaging().fcmToken else { return }
        print("======> FCM \(fcmToken)")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.addValue(pointerToken,
                         forHTTPHeaderField: "Authorization")
        let postString = "fcm_token=\(fcmToken)"
        request.httpBody = postString.data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {                                                 // check for fundamental networking error
                print("error=\(error!)")
                return
            }
            
            let _ = String(data: data, encoding: .utf8)
            print("Sent FCM TOKEN!!!!")
        }
        task.resume()
    }
}

