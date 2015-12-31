//
//  AccountViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 22-07-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation
import UIKit
import MMDrawerController
import SVProgressHUD
import Alamofire
import SwiftyJSON

class AccountViewController : UITableViewController
{
    @IBOutlet weak var accountNameLabel: UILabel!
    @IBOutlet weak var bioLabel: UILabel!
    @IBOutlet weak var accountIDLabel: UILabel!
    @IBOutlet weak var registeredEmailLabel: UILabel!
    @IBOutlet weak var createdOnLabel: UILabel!
    @IBOutlet weak var updatedOnLabel: UILabel!
    @IBOutlet weak var twitchPartnerLabel: UILabel!
    
    @IBOutlet weak var emailNotificationsLabel: UILabel!
    @IBOutlet weak var mobileNotificationsLabel: UILabel!
    @IBOutlet weak var accountImageView: UIImageView!
    
    private var username: String?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let leftBarButtonItem = MMDrawerBarButtonItem(target: self, action: "leftBarButtonPressed:")
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        
        // create a refresh controller
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "pullDownTriggered", forControlEvents: .ValueChanged)
        
        loadAccount(true)
    }
    
    func leftBarButtonPressed(b: UIBarButtonItem)
    {
        self.mm_drawerController.toggleDrawerSide(.Left, animated: true, completion: nil)
    }
    
    func pullDownTriggered()
    {
        loadAccount(false)
    }
    
    func loadAccount(showHUD: Bool)
    {
        if showHUD { SVProgressHUD.showWithStatus("Loading") }
        
        TwitchRequestManager.manager!.request(.GET, "https://api.twitch.tv/kraken/user")
            .responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            SVProgressHUD.dismiss()
            self.refreshControl?.endRefreshing()
            if result.isSuccess
            {
                var responseJSON = JSON(result.value!)
                
                if responseJSON["status"] == 401 {
                    let errorAlertView = UIAlertView(title: "Error", message: "You are unauthorized to make this call. Try to logout and login with your account under Settings.", delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                    
                    self.refreshControl?.endRefreshing()
                    
                    return
                }
                
                self.accountNameLabel.text = responseJSON["display_name"].description
                self.bioLabel.text = (responseJSON["bio"].description == "null") ? "No bio available" : responseJSON["bio"].description
                self.accountIDLabel.text = responseJSON["_id"].description
                self.registeredEmailLabel.text = responseJSON["email"].description
                
                let formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                
                let createdDate = formatter.dateFromString(responseJSON["created_at"].description)
                let updatedDate = formatter.dateFromString(responseJSON["updated_at"].description)
                
                let outFormatter = NSDateFormatter()
                outFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                self.createdOnLabel.text = outFormatter.stringFromDate(createdDate!)
                self.updatedOnLabel.text = outFormatter.stringFromDate(updatedDate!)
                
                self.twitchPartnerLabel.text = responseJSON["partner"].boolValue ? "Yes" : "No"
                self.emailNotificationsLabel.text = responseJSON["notifications"]["email"].boolValue ? "Yes" : "No"
                self.mobileNotificationsLabel.text = responseJSON["notifications"]["push"].boolValue ? "Yes" : "No"
                
                self.username = responseJSON["name"].description
                
                var logoURL = responseJSON["logo"].description
                logoURL = logoURL.stringByReplacingOccurrencesOfString("http://", withString: "https://")
                if logoURL != "null"
                {
                    self.accountImageView.setImageWithURL(NSURL(string: logoURL)!, placeholderImage: UIImage(named: "channel_placeholder"))
                }
            }
            else
            {
                print(result)
                let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                errorAlertView.show()
                
                SVProgressHUD.dismiss()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "FollowingSegue"
        {
            let vc = segue.destinationViewController as! FollowingViewController
            vc.username = self.username
        }
        else if segue.identifier == "BlockedUsersSegue"
        {
            let vc = segue.destinationViewController as! BlockedUsersViewController
            vc.username = self.username
        }
    }
}