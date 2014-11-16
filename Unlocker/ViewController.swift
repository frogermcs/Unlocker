//
//  ViewController.swift
//  Unlocker
//
//  Created by Miroslaw Stanek on 15.11.2014.
//
//

import UIKit
import XCGLogger
import Alamofire
import CoreMotion

public let BeaconUUID = NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")
public let BeaconMajor: CLBeaconMajorValue = 356
public let BeaconMinor: CLBeaconMinorValue = 17311

public let SparkBasePath = "https://api.spark.io/v1/"

public enum Orientation: String {
    case PORTRAIT = "Portrait"
    case LANDSCAPE = "Landscappe"
    case UNKNOWN = "Unknown"
}

class ViewController: UIViewController, ESTBeaconManagerDelegate {

    @IBOutlet weak var lblUnlocked: UILabel!
    
    var beaconManager = ESTBeaconManager()
    var beaconRegion: ESTBeaconRegion!
    
    let motionManager = CMMotionManager()
    var currentOrientation: Orientation?
    var orientationChanged = false
    
    var isCurrentlyUnlocked = false
    
    let enterNotification = UILocalNotification()
    let exitNotification = UILocalNotification()
    let openNotification = UILocalNotification()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUnlocked(false)
        
        initBeaconManager()
        initBeaconRegion()

        beaconManager.requestAlwaysAuthorization()
        
        beaconManager.startMonitoringForRegion(self.beaconRegion)
        beaconManager.requestStateForRegion(self.beaconRegion)
        beaconManager.startRangingBeaconsInRegion(self.beaconRegion)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:"unlockDevice", name: "UnlockPressed", object: nil)
    }

    func startAccelerometerUpdates() {
        self.currentOrientation = Orientation.UNKNOWN
        
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.gyroUpdateInterval = 0.2
        motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue()) {
            (data, error) in
            dispatch_async(dispatch_get_main_queue()) {
                self.outputAccelerationData(data.acceleration)
            }
        }
    }
    
    func outputAccelerationData(data: CMAcceleration) {
        var newOrientation: Orientation
        
        if (data.x >= 0.75) {
            newOrientation = Orientation.LANDSCAPE
        } else if (data.x <= -0.75) {
            newOrientation = Orientation.LANDSCAPE
        } else if (data.y <= -0.75) {
            newOrientation = Orientation.PORTRAIT
        } else if (data.y >= 0.75) {
            newOrientation = Orientation.PORTRAIT
        } else {
            newOrientation = Orientation.UNKNOWN
        }
        
        if (newOrientation != Orientation.UNKNOWN && newOrientation != self.currentOrientation) {
            self.currentOrientation = newOrientation
            self.orientationChanged = newOrientation == Orientation.LANDSCAPE
            log.debug("New orientation \(self.currentOrientation?.rawValue)")
        }
    }
    
    func initBeaconManager() {
        beaconManager.delegate = self
        beaconManager.avoidUnknownStateBeacons = true;
    }
    
    func initBeaconRegion() {
        beaconRegion = ESTBeaconRegion(proximityUUID: BeaconUUID, major: BeaconMajor, minor: BeaconMinor, identifier: "Unlocker")
        beaconRegion?.notifyEntryStateOnDisplay = true
    }

// MARK: BeaconManager delegate
    func beaconManager(manager: ESTBeaconManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        log.debug("Auth: \(status)")
    }
    
    func beaconManager(manager: ESTBeaconManager!, didFailDiscoveryInRegion region: ESTBeaconRegion!) {
        log.debug("Did fail")
    }
    
    func beaconManager(manager: ESTBeaconManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: ESTBeaconRegion!) {
        if (self.orientationChanged) {
            log.debug("Orientation changed, contact with spark")
            unlockDevice()
            
            UIApplication.sharedApplication().cancelAllLocalNotifications()
            motionManager.stopAccelerometerUpdates()
        }
        
        self.orientationChanged = false
    }
    
    func beaconManager(manager: ESTBeaconManager!, didEnterRegion region: ESTBeaconRegion!) {
        log.debug("Did enter region")
        showEnterNotification()
        startAccelerometerUpdates()
    }

    func beaconManager(manager: ESTBeaconManager!, didExitRegion region: ESTBeaconRegion!) {
        log.debug("Did exit region")
//        showExitNotification()
        UIApplication.sharedApplication().cancelAllLocalNotifications()
    }
    
    func beaconManager(manager: ESTBeaconManager!, didDetermineState state: CLRegionState, forRegion region: ESTBeaconRegion!) {
        if (state == CLRegionState.Inside) {
            showEnterNotification()
            startAccelerometerUpdates()
        }
        log.debug("Did determine state \(state.rawValue)")
    }

    
// MARK: Notifications
    
    func showEnterNotification() {
        enterNotification.category = UnlockCategoryId
        enterNotification.alertBody = "Rotate phone to unlock the door"
        enterNotification.soundName = UILocalNotificationDefaultSoundName
        
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        UIApplication.sharedApplication().presentLocalNotificationNow(enterNotification)
    }
    
    func showUnlockedNotification() {
        openNotification.category = UnlockCategoryId
        openNotification.alertBody = "Door unlocked"
        openNotification.soundName = UILocalNotificationDefaultSoundName
        
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        UIApplication.sharedApplication().presentLocalNotificationNow(openNotification)
    }
    
    func showExitNotification() {
        exitNotification.alertBody = "Exit"
        exitNotification.soundName = UILocalNotificationDefaultSoundName
        
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        UIApplication.sharedApplication().presentLocalNotificationNow(exitNotification)
    }
    
// MARK: REST
    
    func unlockDevice() {
        Alamofire
            .request(.POST, SparkBasePath + "devices/55ff6c065075555320461487/unlockDevice")
            .responseJSON{ (request, response, json, error) in
                println(request)
                println(json)
                self.showUnlockedNotification()
                self.setUnlocked(true)
                let delay = 5 * Double(NSEC_PER_SEC)
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
                dispatch_after(time, dispatch_get_main_queue(), {
                    log.debug("Set locked")
                    self.setUnlocked(false)
                    UIApplication.sharedApplication().cancelLocalNotification(self.openNotification)
                })
            }
    }
    
// MARK: UIButtons
    
    @IBAction func unlockDevice(sender: AnyObject) {
        unlockDevice()
    }
    
// MARK: other
    
    func setUnlocked(unlocked: Bool) {
        log.debug("Unlocked \(unlocked)")
        self.isCurrentlyUnlocked = unlocked
        if (self.isCurrentlyUnlocked) {
            lblUnlocked.text = "Unlocked"
        } else {
            lblUnlocked.text = "Locked"
        }
    }
}

