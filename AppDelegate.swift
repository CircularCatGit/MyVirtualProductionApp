// AppDelegate.swift
import UIKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // The physical UIWindow acts as the canvas containing all visual views
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 1. Manually build the root window to fit the exact pixel scale of your iPhone
        window = UIWindow(frame: UIScreen.main.bounds)
        
        // 2. Attach your custom ViewController as the absolute manager of the screen
        let rootVC = ViewController()
        window?.rootViewController = rootVC
        
        // 3. Make the window visible to trigger ARKit and camera tracking loops
        window?.makeKeyAndVisible()
        
        return true
    }
}
