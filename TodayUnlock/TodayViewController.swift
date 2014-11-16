//
//  TodayViewController.swift
//  TodayUnlock
//
//  Created by Miroslaw Stanek on 15.11.2014.
//
//

import UIKit
import NotificationCenter
import Alamofire

let AuthToken = "Bearer 438a7142a2bc6ac12b8c2c29f66db879bc2e800c"
public let SparkBasePath = "https://api.spark.io/v1/"

class TodayViewController: UIViewController, NCWidgetProviding {
    
    override func awakeFromNib() {
        self.preferredContentSize.height = 120
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        Alamofire.Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders = ["Authorization": AuthToken]
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        completionHandler(NCUpdateResult.NewData)
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero;
    }
    
    @IBAction func unlockDoor(sender: AnyObject) {
        Alamofire
            .request(.POST, SparkBasePath + "devices/55ff6c065075555320461487/unlockDevice")
            .responseJSON{ (request, response, json, error) in
                println(request)
                println(json)
        }
    }
}
