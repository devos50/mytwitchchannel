//
//  AppDelegate.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 09-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import UIKit
import MMDrawerController
import SVProgressHUD
import Fabric
import Crashlytics
import GoogleMobileAds

let AD_ID = "ca-app-pub-7225770687990392/7394127466"
let gadTestDevices = [ kGADSimulatorID, "69c340aefb538925732f68b596093eca" ]

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        Fabric.with([Crashlytics.self])
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let menuNavigationController = storyboard.instantiateViewControllerWithIdentifier("MenuNavigationController") as! UINavigationController
        let centerNavigationController = storyboard.instantiateViewControllerWithIdentifier("ChannelNavigationController") as! UINavigationController
        
        let drawerController = MMDrawerController(centerViewController: centerNavigationController, leftDrawerViewController: menuNavigationController)
        drawerController?.showsShadow = false
        drawerController?.maximumLeftDrawerWidth = 230
        
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = drawerController
        self.window!.makeKeyAndVisible()
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        
        TwitchRequestManager.initializeManager()
        SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.Black)
        
        // initialize some NSUserDefault variables
        if NSUserDefaults.standardUserDefaults().stringForKey("StreamQuality") == nil
        {
            NSUserDefaults.standardUserDefaults().setObject("medium", forKey: "StreamQuality")
        }
        if NSUserDefaults.standardUserDefaults().stringForKey("StreamOrientation") == nil
        {
            NSUserDefaults.standardUserDefaults().setObject("portrait", forKey: "StreamOrientation")
        }
        if NSUserDefaults.standardUserDefaults().stringForKey("EnableAds") == nil
        {
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "EnableAds")
        }
        NSUserDefaults.standardUserDefaults().synchronize()
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

