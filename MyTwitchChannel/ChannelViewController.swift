//
//  ChannelViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 27-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation

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
    
    private var channelName: String?
    private var editActionSheet: UIActionSheet?
    private var editStreamGameAlertView: UIAlertView?
    private var editStreamTitleAlertView: UIAlertView?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let leftBarButtonItem = MMDrawerBarButtonItem(target: self, action: "leftBarButtonPressed:")
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        
        editActionSheet = UIActionSheet(title: "Edit", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Edit stream title", "Edit stream game")
        
        // create a refresh controller
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "pullDownTriggered", forControlEvents: .ValueChanged)
        
        loadUserData(true)
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
        loadUserData(false)
    }
    
    func loadChannel()
    {
        TwitchRequestManager.manager!.request(.GET, "https://api.twitch.tv/kraken/channel")
            .responseJSON { (request, response, data, error) in
                if (error != nil)
                {
                    let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                    return
                }
                var responseJSON = JSON(data!)
                
                println(responseJSON)
                
                self.streamTitleLabel.text = responseJSON["status"].description
                self.streamGameLabel.text = responseJSON["game"].description
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
                
                self.loadNumberSubscriptions()
        }
    }
    
    func loadNumberSubscriptions()
    {
        TwitchRequestManager.manager!.request(.GET, "https://api.twitch.tv/kraken/channels/" + self.channelName! + "/subscriptions")
            .responseJSON { (request, response, data, error) in
                if (error != nil)
                {
                    let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                    return
                }
                var responseJSON = JSON(data!)
                if response!.statusCode == 422 { self.subscribersLabel.text = "-" }
                else { self.subscribersLabel.text = responseJSON["_total"].description }
                
                self.refreshControl?.endRefreshing()
                SVProgressHUD.dismiss()
        }
    }
    
    func loadUserData(showHUD: Bool)
    {
        if showHUD { SVProgressHUD.showWithStatus("Loading") }
        TwitchRequestManager.manager!.request(.GET, "https://api.twitch.tv/kraken/user")
            .responseJSON { (request, response, data, error) in
                if (error != nil)
                {
                    self.refreshControl?.endRefreshing()
                    SVProgressHUD.dismiss()
                    let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                    return
                }
                var responseJSON = JSON(data!)
                self.channelName = responseJSON["name"].description
                if responseJSON["partnered"].boolValue { self.partneredLabel.text = "Yes" }
                else { self.partneredLabel.text = "No" }
                
                self.loadChannel()
        }
    }
    
    func updateStreamTitle(newTitle: String)
    {
        SVProgressHUD.showWithStatus("Saving")
        
        TwitchRequestManager.manager!.request(.PUT, "https://api.twitch.tv/kraken/channels/" + channelName!, parameters: ["channel" : ["status" : newTitle]], encoding: ParameterEncoding.URL)
            .responseJSON { (request, response, data, error) in
                SVProgressHUD.dismiss()
                if (error != nil)
                {
                    self.refreshControl?.endRefreshing()
                    SVProgressHUD.dismiss()
                    let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                    return
                }
                self.streamTitleLabel.text = newTitle
                var responseJSON = JSON(data!)
        }
    }
    
    func updateStreamGame(newGame: String)
    {
        SVProgressHUD.showWithStatus("Saving")
        
        TwitchRequestManager.manager!.request(.PUT, "https://api.twitch.tv/kraken/channels/" + channelName!, parameters: ["channel" : ["game" : newGame]], encoding: ParameterEncoding.URL)
            .responseJSON { (request, response, data, error) in
                SVProgressHUD.dismiss()
                if (error != nil)
                {
                    self.refreshControl?.endRefreshing()
                    SVProgressHUD.dismiss()
                    let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                    return
                }
                self.streamGameLabel.text = newGame
                var responseJSON = JSON(data!)
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
    }
}

extension ChannelViewController: UIAlertViewDelegate
{
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int)
    {
        if alertView == editStreamTitleAlertView && buttonIndex == 1
        {
            updateStreamTitle(alertView.textFieldAtIndex(0)!.text)
        }
        else if alertView == editStreamGameAlertView && buttonIndex == 1
        {
            updateStreamGame(alertView.textFieldAtIndex(0)!.text)
        }
    }
}