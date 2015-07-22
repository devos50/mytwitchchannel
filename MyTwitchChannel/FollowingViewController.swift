//
//  FollowingViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 27-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation

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
            .responseJSON { (request, response, data, error) in
                SVProgressHUD.dismiss()
                if (error != nil)
                {
                    let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                    return
                }
                var responseJSON = JSON(data!)
                println(responseJSON)
                self.nextURL = responseJSON["_links"]["next"].description
                for follower in responseJSON["follows"]
                {
                    self.following.append(follower.1)
                }
                
                self.tableView.reloadData()
        }
    }
}

extension FollowingViewController: UITableViewDataSource, UITableViewDelegate
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
            var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("LoadMoreCell") as? UITableViewCell
            if(cell == nil)
            {
                cell = UITableViewCell(style: .Default, reuseIdentifier: "LoadMoreCell")
            }
            return cell!
        }
        
        var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("FollowingCell") as? UITableViewCell
        if(cell == nil)
        {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "FollowingCell")
        }
        
        let followingImageView = cell!.viewWithTag(1) as! UIImageView
        let followingNameLabel = cell!.viewWithTag(2) as! UILabel
        
        followingNameLabel.text = following[indexPath.row]["channel"]["display_name"].description
        let logoURL = following[indexPath.row]["channel"]["logo"].description
        
        followingImageView.setImageWithURL(NSURL(string: logoURL)!, placeholderImage: UIImage(named: "channel_placeholder"))
        
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