//
//  SceneDelegate.swift
//  Profix
//
//  Created by Haneen on 03/12/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    static private(set) var current: SceneDelegate?
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        SceneDelegate.current = self
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        window?.overrideUserInterfaceStyle = .light
        
        let vc = SplashVC(nibName: "SplashVC", bundle: nil)
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        NotificationCenter.default.post(name: .appDidBecomeActive, object: nil)
    }

}

