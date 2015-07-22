//
//  FollowersViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 27-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation

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
                    self.followers.append(follower.1)
                }
                
                self.tableView.reloadData()
        }
    }
}

extension FollowersViewController: UITableViewDataSource, UITableViewDelegate
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
            var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("LoadMoreCell") as? UITableViewCell
            if(cell == nil)
            {
                cell = UITableViewCell(style: .Default, reuseIdentifier: "LoadMoreCell")
            }
            return cell!
        }
        
        var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("FollowerCell") as? UITableViewCell
        if(cell == nil)
        {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "FollowerCell")
        }
        
        let followerImageView = cell!.viewWithTag(1) as! UIImageView
        let followerNameLabel = cell!.viewWithTag(2) as! UILabel
        
        followerNameLabel.text = followers[indexPath.row]["user"]["display_name"].description
        let logoURL = followers[indexPath.row]["user"]["logo"].description

        followerImageView.setImageWithURL(NSURL(string: logoURL)!)
        
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