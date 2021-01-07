//
//  AppDelegate.swift
//  SampleAws
//
//  Created by Akansha Dixit on 06/01/21.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var backgroundCompletionHandler : ( () -> Void )?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
            debugPrint("handleEventsForBackgroundURLSession: \(identifier)")
            backgroundCompletionHandler = completionHandler
        }


}

