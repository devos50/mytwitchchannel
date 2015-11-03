//
//  FollowingViewController.swift
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

class FollowingViewController: UITableViewController
{
    private var following = [JSON]()
    var username: String?
    var currentURL: String?
    var nextURL: String?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        currentURL = "https://api.twitch.tv/kraken/users/" + username! + "/follows/channels"
        
        loadFollowing(false)
    }
    
    func loadFollowing(loadNext: Bool)
    {
        if !loadNext { following = [] }
        SVProgressHUD.showWithStatus("Loading")
        TwitchRequestManager.manager!.request(.GET, loadNext ? nextURL! : currentURL!)
            .responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            SVProgressHUD.dismiss()
            
            if result.isSuccess
            {
                var responseJSON = JSON(result.value!)
                print(responseJSON)
                self.nextURL = responseJSON["_links"]["next"].description
                for follower in responseJSON["follows"]
                {
                    self.following.append(follower.1)
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
}

extension FollowingViewController
{
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if following.count == 0 { return 0 }
        return following.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if indexPath.section == 0 && indexPath.row == following.count
        {
            var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("LoadMoreCell")
            if(cell == nil)
            {
                cell = UITableViewCell(style: .Default, reuseIdentifier: "LoadMoreCell")
            }
            return cell!
        }
        
        var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("FollowingCell")
        if(cell == nil)
        {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "FollowingCell")
        }
        
        let followingImageView = cell!.viewWithTag(1) as! UIImageView
        let followingNameLabel = cell!.viewWithTag(2) as! UILabel
        let followingDetailLabel = cell!.viewWithTag(3) as! UILabel
        
        followingNameLabel.text = following[indexPath.row]["channel"]["display_name"].description
        var logoURL = following[indexPath.row]["channel"]["logo"].description
        logoURL = logoURL.stringByReplacingOccurrencesOfString("http://", withString: "https://")
        
        followingImageView.setImageWithURL(NSURL(string: logoURL)!, placeholderImage: UIImage(named: "channel_placeholder"))
        
        followingDetailLabel.text = "Followers: " + following[indexPath.row]["channel"]["followers"].description
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 54
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if indexPath.section == 0 && indexPath.row == following.count
        {
            loadFollowing(true)
        }
    }
}