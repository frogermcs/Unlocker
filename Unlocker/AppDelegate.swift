//
//  AppDelegate.swift
//  Unlocker
//
//  Created by Miroslaw Stanek on 15.11.2014.
//
//

import UIKit
import XCGLogger
import Alamofire

public let log = XCGLogger.defaultInstance()
public let AuthToken = "Bearer 438a7142a2bc6ac12b8c2c29f66db879bc2e800c"
public let UnlockActionId = "UNLOCK"
public let UnlockCategoryId = "CATEGORY"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: true);
        log.setup(logLevel: .Debug, showLogLevel: true, showFileNames: false, showLineNumbers: true, writeToFile: nil)
        Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders = ["Authorization": AuthToken]
        registerForLocalNotification(application)
        
        return true
    }
    
    func registerForLocalNotification(application: UIApplication) {
        var notifyAction:UIMutableUserNotificationAction = UIMutableUserNotificationAction()
        notifyAction.identifier = UnlockActionId
        notifyAction.title = "Unlock"
        notifyAction.activationMode = UIUserNotificationActivationMode.Background
        notifyAction.destructive = false
        notifyAction.authenticationRequired = false
        
        var notifyCategory:UIMutableUserNotificationCategory = UIMutableUserNotificationCategory()
        notifyCategory.identifier = UnlockCategoryId
        notifyCategory.setActions([notifyAction], forContext: UIUserNotificationActionContext.Default)
        notifyCategory.setActions([notifyAction], forContext: UIUserNotificationActionContext.Minimal)
        
        if(UIApplication.instancesRespondToSelector(Selector("registerUserNotificationSettings:"))) {
            application.registerUserNotificationSettings(
                UIUserNotificationSettings(
                    forTypes: UIUserNotificationType.Sound | UIUserNotificationType.Alert | UIUserNotificationType.Badge,
                    categories: NSSet(objects: notifyCategory)
                )
            )
        }
    }
    
    func application(application: UIApplication!,
        handleActionWithIdentifier identifier:String!,
        forLocalNotification notification:UILocalNotification!,
        completionHandler: (() -> Void)!){
            if (identifier == UnlockActionId){
                NSNotificationCenter.defaultCenter().postNotificationName("UnlockPressed", object: nil)
            }
            
            completionHandler()
    }

    
    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
    }


}

