//
//  AppDelegate.swift
//  Aste
//
//  Created by Michele on 08/11/16.
//  Copyright © 2016 Michele Percich. All rights reserved.
//

import UIKit
import os
import Firebase
import FirebaseMessaging
import FirebaseInstanceID
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let AUTH_TOKEN = "eyJhbGciOiJSUzI1NiIsImtpZCI6Ijg2MDgzMDc4ZGQxMzc4NzgxZjMxYzI2ZjVkZWNjMzIzYTM0OTVlZWIiLCJ0eXAiOiJKV1QifQ.eyJhdWQiOiJodHRwczovL2lkZW50aXR5dG9vbGtpdC5nb29nbGVhcGlzLmNvbS9nb29nbGUuaWRlbnRpdHkuaWRlbnRpdHl0b29sa2l0LnYxLklkZW50aXR5VG9vbGtpdCIsImV4cCI6MTQ4MzAwMzg1NSwiaWF0IjoxNDgzMDAwMjU1LCJpc3MiOiJmaXJlYmFzZS1hZG1pbnNkay1scmEyY0Bhc3RlLTQwNGQzLmlhbS5nc2VydmljZWFjY291bnQuY29tIiwic3ViIjoiZmlyZWJhc2UtYWRtaW5zZGstbHJhMmNAYXN0ZS00MDRkMy5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIsInVzZXJfaWQiOiJhZG1pbiIsInNjb3BlIjoiaHR0cHM6Ly93d3cuZ29vZ2xlYXBpcy5jb20vYXV0aC9pZGVudGl0eXRvb2xraXQifQ.J2LcVAhRc1MbQbqwtlkwrY-VZ041_W7vKeQ523MT3-FrRNGiksi0aYw8mTt6NOsrCKpcYuna-96M59oyI6_AMpML7WoI83HFIFGFpV5LWtfTvWYhY_3nuxsB_3DPRZIeyQFLhmXZqJ_1PuG9RTDvvwsSv4mCXqifoumvQfU6ABTGT5ANU4i3tQufKBEQhymgvOnuRlwgptxHEkppQJqWqH10Hf4XmGSLYDG55pH7zy6XeK1Kz0x1RBV_afkS27OqHPOPMifszFWpjrh5Q3fb0tu2VDCNzn-JP6M2U6Adbff2q43r1F2wOoJIABdaKjGD-XG1l-oRCN969WjUmBNlgw"
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        FIRApp.configure();
        // Override point for customization after application launch.
        if #available(iOS 10.0, *) {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            // For iOS 10 data message (sent via FCM)
            FIRMessaging.messaging().remoteMessageDelegate = self
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        do {
            try FIRAuth.auth()?.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: \(signOutError)")
        } catch {
            print("Unknown error.")
        }
        FIRAuth.auth()?.signIn(withEmail: "mpercich@me.com", password: "valentina") { (user, error) in
            if let error = error {
                print("Authentication failed with error: \(error.localizedDescription)")
            } else {
                print("Authentication successfull for user: \(user?.email)")
            }
        }
        /*
        FIRAuth.auth()?.signIn(withCustomToken: AUTH_TOKEN, completion: { (user, error) in
            if let error = error {
                print("Authentication failed with error: \(error.localizedDescription)")
            } else {
                print("Authentication successfull for user: \(user?.email)")
            }
        })
        */
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.tokenRefreshNotification),
                                               name: .firInstanceIDTokenRefresh,
                                               object: nil)
                if let token = FIRInstanceID.instanceID().token() {
                    print("token is < \(token) >:")
                }
        if let remoteNotification = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as! [NSObject : AnyObject]? {
            os_log("App received notification from remote %s", type: .info, remoteNotification)
                self.application(application, didReceiveRemoteNotification: remoteNotification)
        } else {
            os_log("App did not receive notification", type: .info)
        }
        return true
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // Print message ID.
        print("Message ID: \(userInfo["gcm.message_id"]!)")
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // Print message ID.
        print("Message ID: \(userInfo["gcm.message_id"]!)")
        // Print full message.
        print(userInfo)
    }
    
    // [END receive_message]
    // [START refresh_token]
    func tokenRefreshNotification(_ notification: Notification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            print("InstanceID token: \(refreshedToken)")
        }
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
    }
    // [END refresh_token]
    // [START connect_to_fcm]
    func connectToFcm() {
        FIRMessaging.messaging().connect { (error) in
            if error != nil {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    // [END connect_to_fcm]
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the InstanceID token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        // With swizzling disabled you must set the APNs token here.
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.sandbox)
        FIRMessaging.messaging().subscribe(toTopic: "/topics/aste_new")
        FIRMessaging.messaging().subscribe(toTopic: "/topics/aste_changed")
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        connectToFcm()
    }
    // [START disconnect_from_fcm]
    func applicationDidEnterBackground(_ application: UIApplication) {
        FIRMessaging.messaging().disconnect()
        print("Disconnected from FCM.")
    }
    // [END disconnect_from_fcm]
}

// [START ios_10_data_message_handling]
extension AppDelegate: FIRMessagingDelegate {
    // Receive data message on iOS 10 devices while app is in the foreground.
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        print(remoteMessage.appData)
    }
}
// [END ios_10_data_message_handling]
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

    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
    }

@available(iOS 10, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        // Print full message.
        print(userInfo)
        completionHandler([.badge, .alert, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        print("Message ID: \(userInfo["gcm.message_id"]!)")
        print("Key: \(userInfo["Codice"]!)")
        print("Prezzo: \(userInfo["Prezzo"]!)")
        print("Indirizzo: \(userInfo["Indirizzo"]!)")
        let key = userInfo["Codice"] as! String
        let nav: UINavigationController = window!.rootViewController as! UINavigationController
        if !(nav.topViewController is TableViewController) {
            for controller in nav.viewControllers {
                if controller is TableViewController {
                    nav.popToViewController(controller, animated: true)
                }
            }
        }
        let tableViewController = nav.topViewController as! TableViewController
        tableViewController.rowToScroll = key as String?
        if tableViewController.aste.count > 0 {
            tableViewController.scroll()
        }
        completionHandler()
    }
}


