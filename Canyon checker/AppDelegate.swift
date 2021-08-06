//
//  AppDelegate.swift
//  Canyon checker
//
//  Created by Sébastien Hannay on 01/08/2021.
//

import UIKit
import UserNotifications
import BackgroundTasks

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        let notificationCenter = UNUserNotificationCenter.current()
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "canyonChecker.checkAll", using: nil) { task in
            task.expirationHandler = {
                print("Background bike check expired")
                task.setTaskCompleted(success: false)
                BikeChecker.registerBackgroundTask()
            }
            print("Background bike check started")
            BikeChecker.shared.checkAllAndNotify() {
                print("Background bike check done")
                task.setTaskCompleted(success: true)
                BikeChecker.registerBackgroundTask()
            }
        }
        
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }


}

