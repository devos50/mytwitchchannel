//
//  ChatViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 22-07-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation
import Alamofire
import MMDrawerController

class ChatViewController: UIViewController
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var rightButton: UIBarButtonItem!
    private var chatManager = IRCManager.sharedManager
    private var chatMessages = [ChatMessage]()
    private var isInChannel = false
    private var enterChannelAlert: UIAlertView?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let leftBarButtonItem = MMDrawerBarButtonItem(target: self, action: "leftBarButtonPressed:")
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        
        chatManager.delegate = self
        updateUI()
        
        chatManager.connect()
    }
    
    func updateUI () {
        dispatch_async(dispatch_get_main_queue(),{
            if !self.isInChannel {
                let emptyStateLabel = UILabel(frame: self.tableView.frame)
                emptyStateLabel.text = "No joined channel"
                emptyStateLabel.numberOfLines = 0
                emptyStateLabel.textColor = UIColor.grayColor()
                emptyStateLabel.font = UIFont.boldSystemFontOfSize(24)
                emptyStateLabel.textAlignment = NSTextAlignment.Center
                self.tableView.tableFooterView = UIView(frame: CGRectZero)
                self.rightButton.title = "Join"
                // style it
                
                self.tableView.backgroundView = emptyStateLabel
            } else {
                self.tableView.backgroundView = nil
                self.rightButton.title = "Leave"
            }
        })
    }
    
    func leftBarButtonPressed(b: UIBarButtonItem)
    {
        self.mm_drawerController.toggleDrawerSide(.Left, animated: true, completion: nil)
    }
    
    @IBAction func rightBarButtonPressed()
    {
        if !isInChannel
        {
            enterChannelAlert = UIAlertView(title: "Enter Channel", message: "Enter the channel you wish to join.", delegate: self, cancelButtonTitle: "Close", otherButtonTitles: "Join")
            enterChannelAlert?.alertViewStyle = .PlainTextInput
            enterChannelAlert?.textFieldAtIndex(0)!.placeholder = "Channel name"
            enterChannelAlert?.show()
        }
        else
        {
            chatManager.leaveCurrentChannel()
            isInChannel = false
            updateUI()
        }
    }
}

extension ChatViewController: UITableViewDataSource, UITableViewDelegate
{
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return chatMessages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("ChatMessageCell")
        if(cell == nil)
        {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "ChatMessageCell")
        }
        return cell!
    }
}

extension ChatViewController: IRCManagerDelegate
{
    func receivedChatMessage(message: ChatMessage)
    {
        chatMessages.append(message)
        self.tableView.reloadData()
    }
}

extension ChatViewController: UIAlertViewDelegate
{
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int)
    {
        if alertView == enterChannelAlert && buttonIndex == 1
        {
            let enteredText = enterChannelAlert!.textFieldAtIndex(0)!.text!
            if enteredText.characters.count == 0
            {
                let errorAlert = UIAlertView(title: "Error", message: "Please enter a channel name.", delegate: nil, cancelButtonTitle: "Close")
                errorAlert.show()
                return
            }
            
            chatManager.joinChannel(enteredText)
            isInChannel = true
            updateUI()
            self.tableView.reloadData()
        }
    }
}