//
//  FollowersViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 27-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation
import SVProgressHUD
import SwiftyJSON
import Alamofire
import AFNetworking

class FollowersViewController: UITableViewController
{
    private var followers = [JSON]()
    var channelName: String?
    var currentURL: String?
    var nextURL: String?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        currentURL = "https://api.twitch.tv/kraken/channels/" + channelName! + "/follows"
        
        loadFollowers(false)
    }
    
    func loadFollowers(loadNext: Bool)
    {
        if !loadNext { followers = [] }
        SVProgressHUD.showWithStatus("Loading")
        
        TwitchRequestManager.manager!.request(.GET, loadNext ? nextURL! : currentURL!).responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            if result.isSuccess {
                var responseJSON = JSON(result.value!)
                self.nextURL = responseJSON["_links"]["next"].description
                for follower in responseJSON["follows"]
                {
                    self.followers.append(follower.1)
                }
                
                SVProgressHUD.dismiss()
                self.tableView.reloadData()
            } else {
                let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                errorAlertView.show()
                SVProgressHUD.dismiss()
            }
        }
    }
}

extension FollowersViewController
{
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if followers.count == 0 { return 0 }
        return followers.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if indexPath.section == 0 && indexPath.row == followers.count
        {
            var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("LoadMoreCell")
            if(cell == nil)
            {
                cell = UITableViewCell(style: .Default, reuseIdentifier: "LoadMoreCell")
            }
            return cell!
        }
        
        var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("FollowerCell")
        if(cell == nil)
        {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "FollowerCell")
        }
        
        let followerImageView = cell!.viewWithTag(1) as! UIImageView
        let followerNameLabel = cell!.viewWithTag(2) as! UILabel
        
        followerNameLabel.text = followers[indexPath.row]["user"]["display_name"].description
        var logoURL = followers[indexPath.row]["user"]["logo"].description
        logoURL = logoURL.stringByReplacingOccurrencesOfString("http://", withString: "https://")
        
        followerImageView.setImageWithURL(NSURL(string: logoURL)!, placeholderImage: UIImage(named: "channel_placeholder"))
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 54
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if indexPath.section == 0 && indexPath.row == followers.count
        {
            loadFollowers(true)
        }
    }
}