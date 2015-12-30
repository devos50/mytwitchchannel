//
//  BlockedUsersViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 27-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import Alamofire
import SVProgressHUD

class BlockedUsersViewController: UITableViewController
{
    private var blocked = [JSON]()
    var username: String?
    var currentURL: String?
    var nextURL: String?
    var addBlockedUserAlert: UIAlertView?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        currentURL = "https://api.twitch.tv/kraken/users/" + username! + "/blocks"
        
        loadBlocks(false)
    }
    
    @IBAction func addBlockedUserPressed()
    {
        addBlockedUserAlert = UIAlertView(title: "Block User", message: "Enter the username of the user below.", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Block")
        addBlockedUserAlert?.alertViewStyle = .PlainTextInput
        addBlockedUserAlert?.textFieldAtIndex(0)?.placeholder = "Username"
        addBlockedUserAlert?.show()
    }
    
    func loadBlocks(loadNext: Bool)
    {
        if !loadNext { blocked = [] }
        SVProgressHUD.showWithStatus("Loading")
        TwitchRequestManager.manager!.request(.GET, loadNext ? nextURL! : currentURL!)
            .responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
                SVProgressHUD.dismiss()
                
                if result.isSuccess
                {
                    var responseJSON = JSON(result.value!)
                    print(responseJSON)
                    self.nextURL = responseJSON["_links"]["next"].description
                    for follower in responseJSON["blocks"]
                    {
                        self.blocked.append(follower.1)
                    }
                    
                    self.tableView.reloadData()
                }
                else
                {
                    let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                    return
                }
        }
    }
    
    func blockUser(enteredUsername: String)
    {
        SVProgressHUD.showWithStatus("Saving")
        
        TwitchRequestManager.manager!.request(.PUT, "https://api.twitch.tv/kraken/users/" + username! + "/blocks/" + enteredUsername, parameters: nil, encoding: ParameterEncoding.URL).responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            if result.isSuccess {
                self.loadBlocks(false)
            } else
            {
                let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                errorAlertView.show()
            }
        }
    }
}

extension BlockedUsersViewController
{
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if blocked.count == 0 { return 0 }
        return blocked.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if indexPath.section == 0 && indexPath.row == blocked.count
        {
            var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("LoadMoreCell")
            if(cell == nil)
            {
                cell = UITableViewCell(style: .Default, reuseIdentifier: "LoadMoreCell")
            }
            return cell!
        }
        
        var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("BlockedUserCell")
        if(cell == nil)
        {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "FollowingCell")
        }
        
        let blockedUserImageView = cell!.viewWithTag(1) as! UIImageView
        let blockedUserNameLabel = cell!.viewWithTag(2) as! UILabel
        let blockedUserDetailLabel = cell!.viewWithTag(3) as! UILabel
        
        blockedUserNameLabel.text = blocked[indexPath.row]["user"]["display_name"].description
        var logoURL = blocked[indexPath.row]["user"]["logo"].description
        logoURL = logoURL.stringByReplacingOccurrencesOfString("http://", withString: "https://")
        
        blockedUserImageView.setImageWithURL(NSURL(string: logoURL)!, placeholderImage: UIImage(named: "channel_placeholder"))
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        
        let updatedDate = formatter.dateFromString(blocked[indexPath.row]["user"]["updated_at"].description)
        
        let outFormatter = NSDateFormatter()
        outFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        blockedUserDetailLabel.text = "Blocked: " + outFormatter.stringFromDate(updatedDate!)
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 54
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if indexPath.section == 0 && indexPath.row == blocked.count
        {
            loadBlocks(true)
        }
    }
}

extension BlockedUsersViewController: UIAlertViewDelegate
{
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int)
    {
        if alertView == addBlockedUserAlert
        {
            let enteredText = addBlockedUserAlert!.textFieldAtIndex(0)!.text!
            blockUser(enteredText)
        }
    }
}