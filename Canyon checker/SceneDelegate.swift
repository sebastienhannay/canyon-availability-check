//
//  SceneDelegate.swift
//  Canyon checker
//
//  Created by Sébastien Hannay on 01/08/2021.
//

import UIKit
import BackgroundTasks

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        BikeChecker.registerBackgroundTask()
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }

}

