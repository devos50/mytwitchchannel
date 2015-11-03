//
//  ChannelViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 27-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation
import UIKit
import MMDrawerController
import SVProgressHUD
import Alamofire
import SwiftyJSON

class ChannelViewController: UITableViewController
{
    @IBOutlet weak var partneredLabel: UILabel!
    @IBOutlet weak var streamTitleLabel: UILabel!
    @IBOutlet weak var streamGameLabel: UILabel!
    @IBOutlet weak var subscribersLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var viewsLabel: UILabel!
    @IBOutlet weak var maturityLabel: UILabel!
    
    @IBOutlet weak var channelIDLabel: UILabel!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var updatedAtLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var broadcasterLanguageLabel: UILabel!
    @IBOutlet weak var channelLanguageLabel: UILabel!
    @IBOutlet weak var streamDelayLabel: UILabel!
    @IBOutlet weak var streamImageView: UIImageView!
    
    private var channelName: String?
    private var editActionSheet: UIActionSheet?
    private var editStreamGameAlertView: UIAlertView?
    private var editStreamTitleAlertView: UIAlertView?
    private var showCommercialActionSheet: UIActionSheet?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let leftBarButtonItem = MMDrawerBarButtonItem(target: self, action: "leftBarButtonPressed:")
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        
        editActionSheet = UIActionSheet(title: "Edit", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Edit stream title", "Edit stream game")
        showCommercialActionSheet = UIActionSheet(title: "Show commercial", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "30 sec", "60 sec", "90 sec", "120 sec", "150 sec", "180 sec")
        
        // create a refresh controller
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "pullDownTriggered", forControlEvents: .ValueChanged)
        
        loadChannel(true)
    }
    
    @IBAction func editButtonPressed()
    {
        editActionSheet?.showInView(self.navigationController!.view)
    }
    
    func leftBarButtonPressed(b: UIBarButtonItem)
    {
        self.mm_drawerController.toggleDrawerSide(.Left, animated: true, completion: nil)
    }
    
    func pullDownTriggered()
    {
        loadChannel(false)
    }
    
    func loadChannel(showHUD: Bool)
    {
        if showHUD { SVProgressHUD.showWithStatus("Loading") }
        
        TwitchRequestManager.manager!.request(.GET, "https://api.twitch.tv/kraken/channel").responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            if result.isSuccess {
                var responseJSON = JSON(result.value!)
                
                if responseJSON["status"] == 401 {
                    let errorAlertView = UIAlertView(title: "Error", message: "You are unauthorized to make this call. Try to logout and login with your account under Settings.", delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                    
                    self.refreshControl?.endRefreshing()
                    SVProgressHUD.dismiss()
                    
                    return
                }
                
                self.streamTitleLabel.text = responseJSON["status"].description
                self.streamGameLabel.text = "Playing " + responseJSON["game"].description
                self.followersLabel.text = responseJSON["followers"].description
                self.viewsLabel.text = responseJSON["views"].description
                
                self.channelIDLabel.text = responseJSON["_id"].description
                
                let formatter = NSDateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                
                let createdDate = formatter.dateFromString(responseJSON["created_at"].description)
                let updatedDate = formatter.dateFromString(responseJSON["updated_at"].description)
                
                let outFormatter = NSDateFormatter()
                outFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                
                self.createdAtLabel.text = outFormatter.stringFromDate(createdDate!)
                self.updatedAtLabel.text = outFormatter.stringFromDate(updatedDate!)
                self.displayNameLabel.text = responseJSON["display_name"].description
                self.broadcasterLanguageLabel.text = (responseJSON["broadcast_language"].description == "null") ? "n/a" : responseJSON["broadcast_language"].description
                self.channelLanguageLabel.text = (responseJSON["language"].description == "null") ? "n/a" : responseJSON["language"].description
                
                if responseJSON["maturity"].description == "null" { self.maturityLabel.text = "n/a" }
                else
                {
                    self.maturityLabel.text = (responseJSON["maturity"].boolValue) ? "Yes" : "No"
                }
                
                if responseJSON["delay"].description == "null" { self.streamDelayLabel.text = "0" }
                else { self.streamDelayLabel.text = responseJSON["delay"].description }
                
                if responseJSON["partner"].boolValue { self.partneredLabel.text = "Yes" }
                else { self.partneredLabel.text = "No" }
                self.channelName = responseJSON["name"].description
                
                var logoURL = responseJSON["logo"].description
                logoURL = logoURL.stringByReplacingOccurrencesOfString("http://", withString: "https://")
                if logoURL != "null"
                {
                    self.streamImageView.setImageWithURL(NSURL(string: logoURL)!, placeholderImage: UIImage(named: "channel_placeholder"))
                }
                
                self.loadNumberSubscriptions()
            }
            else {
                let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                errorAlertView.show()
            }
        }
    }
    
    func loadNumberSubscriptions()
    {
        TwitchRequestManager.manager!.request(.GET, "https://api.twitch.tv/kraken/channels" + self.channelName! + "/subscriptions").responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            if result.isSuccess {
                var responseJSON = JSON(result.value!)
                if response!.statusCode == 422 || responseJSON["_total"].description == "null" { self.subscribersLabel.text = "n/a" }
                else { self.subscribersLabel.text = responseJSON["_total"].description }
                
                self.refreshControl?.endRefreshing()
                SVProgressHUD.dismiss()
            } else {
                
                let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                errorAlertView.show()
            }
        }
    }
    
    func updateStreamTitle(newTitle: String)
    {
        SVProgressHUD.showWithStatus("Saving")
        
        TwitchRequestManager.manager!.request(.PUT, "https://api.twitch.tv/kraken/channels/" + channelName!, parameters: ["channel" : ["status" : newTitle]], encoding: ParameterEncoding.URL).responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            if result.isSuccess {
                self.streamTitleLabel.text = newTitle
            } else {
                let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                errorAlertView.show()

            }
        }
    }
    
    func updateStreamGame(newGame: String)
    {
        SVProgressHUD.showWithStatus("Saving")
        
        
        TwitchRequestManager.manager!.request(.PUT, "https://api.twitch.tv/kraken/channels/" + channelName!, parameters: ["channel" : ["game" : newGame]], encoding: ParameterEncoding.URL).responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            if result.isSuccess {
                self.streamGameLabel.text = newGame
            } else
            {
                let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                errorAlertView.show()
            }
        }
    }
    
    func showCommercial(seconds: Int)
    {
        SVProgressHUD.showWithStatus("Saving")
        
        TwitchRequestManager.manager!.request(.POST, "https://api.twitch.tv/kraken/channels/" + channelName! + "/commercial", parameters: ["length" : seconds], encoding: ParameterEncoding.URL).responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            if result.isSuccess {
                if response!.statusCode == 422
                {
                    let errorAlertView = UIAlertView(title: "Error", message: "Unable to start a commercial on this channel. You cannot start a commercial within 8 minutes of a previous commercial. This error also shows up when you are offline or not partnered.", delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                }
                else
                {
                    let successAlertView = UIAlertView(title: "Success", message: "The request has succesfully been submitted.", delegate: nil, cancelButtonTitle: "Close")
                    successAlertView.show()
                }
            } else
            {
                let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                errorAlertView.show()
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if segue.identifier == "FollowersSegue"
        {
            let vc = segue.destinationViewController as! FollowersViewController
            vc.channelName = self.channelName
        }
        else if segue.identifier == "SubscribersSegue"
        {
            let vc = segue.destinationViewController as! SubscriptionsViewController
            vc.channelName = self.channelName
        }
    }
}

extension ChannelViewController
{
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if indexPath.section == 4 && indexPath.row == 0
        {
            showCommercialActionSheet?.showInView(self.navigationController!.view)
        }
    }
}

extension ChannelViewController: UIActionSheetDelegate
{
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int)
    {
        if actionSheet == editActionSheet && buttonIndex == 1
        {
            editStreamTitleAlertView = UIAlertView(title: "Edit stream title", message: "Please enter your new stream title below.", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Save")
            editStreamTitleAlertView?.alertViewStyle = .PlainTextInput
            editStreamTitleAlertView?.textFieldAtIndex(0)!.placeholder = "Stream title"
            editStreamTitleAlertView?.textFieldAtIndex(0)!.text = streamTitleLabel.text
            editStreamTitleAlertView?.show()
        }
        else if actionSheet == editActionSheet && buttonIndex == 2
        {
            editStreamGameAlertView = UIAlertView(title: "Edit stream game", message: "Please enter your new stream game below.", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Save")
            editStreamGameAlertView?.alertViewStyle = .PlainTextInput
            editStreamGameAlertView?.textFieldAtIndex(0)!.placeholder = "Stream game"
            editStreamGameAlertView?.textFieldAtIndex(0)!.text = streamGameLabel.text
            editStreamGameAlertView?.show()
        }
        else if actionSheet == showCommercialActionSheet
        {
            if buttonIndex == 0 { return }
            let seconds = [30, 60, 90, 120, 150, 180]
            let chosenSeconds = seconds[buttonIndex - 1]
            
            showCommercial(chosenSeconds)
        }
    }
}

extension ChannelViewController: UIAlertViewDelegate
{
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int)
    {
        if alertView == editStreamTitleAlertView && buttonIndex == 1
        {
            updateStreamTitle(alertView.textFieldAtIndex(0)!.text!)
        }
        else if alertView == editStreamGameAlertView && buttonIndex == 1
        {
            updateStreamGame(alertView.textFieldAtIndex(0)!.text!)
        }
    }
}