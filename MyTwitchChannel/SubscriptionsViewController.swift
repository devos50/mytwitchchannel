//
//  SubscriptionsViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 01-07-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation

class SubscriptionsViewController: UITableViewController
{
    private var subscribers = [JSON]()
    var channelName: String?
    var currentURL: String?
    var nextURL: String?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        currentURL = "https://api.twitch.tv/kraken/channels/" + channelName! + "/subscriptions"
        
        loadSubscriptions(false)
    }
    
    func loadSubscriptions(loadNext: Bool)
    {
        if !loadNext { subscribers = [] }
        SVProgressHUD.showWithStatus("Loading")
        TwitchRequestManager.manager!.request(.GET, loadNext ? nextURL! : currentURL!)
            .responseJSON { (request, response, data, error) in
                if (error != nil)
                {
                    let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                    SVProgressHUD.dismiss()
                    return
                }
                
                var responseJSON = JSON(data!)
                
                if responseJSON["status"].description == "422"
                {
                    let errorAlertView = UIAlertView(title: "Error", message: responseJSON["message"].description, delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                    SVProgressHUD.dismiss()
                    return
                }
                
                self.nextURL = responseJSON["_links"]["next"].description
                for follower in responseJSON["subscriptions"]
                {
                    self.subscribers.append(follower.1)
                }
                
                self.tableView.reloadData()
                SVProgressHUD.dismiss()
        }
    }
}

extension SubscriptionsViewController: UITableViewDataSource, UITableViewDelegate
{
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if subscribers.count == 0 { return 0 }
        return subscribers.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if indexPath.section == 0 && indexPath.row == subscribers.count
        {
            var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("LoadMoreCell") as? UITableViewCell
            if(cell == nil)
            {
                cell = UITableViewCell(style: .Default, reuseIdentifier: "LoadMoreCell")
            }
            return cell!
        }
        
        var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("SubscriberCell") as? UITableViewCell
        if(cell == nil)
        {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "SubscriberCell")
        }
        
        let followerImageView = cell!.viewWithTag(1) as! UIImageView
        let followerNameLabel = cell!.viewWithTag(2) as! UILabel
        
        followerNameLabel.text = subscribers[indexPath.row]["user"]["display_name"].description
        let logoURL = subscribers[indexPath.row]["user"]["logo"].description
        
        followerImageView.setImageWithURL(NSURL(string: logoURL)!)
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 54
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if indexPath.section == 0 && indexPath.row == subscribers.count
        {
            loadSubscriptions(true)
        }
    }
}