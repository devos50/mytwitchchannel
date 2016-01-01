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
    @IBOutlet weak var chatMessageTextField: UITextField!
    @IBOutlet weak var bottomMargin: NSLayoutConstraint!
    @IBOutlet weak var newMessageView: UIView!
    @IBOutlet weak var sendMessageButton: UIButton!
    private var chatManager = IRCManager.sharedManager
    private var chatMessages = [ChatMessage]()
    private var isInChannel = false
    private var enterChannelAlert: UIAlertView?
    private var tableViewTapRecognizer: UITapGestureRecognizer?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let leftBarButtonItem = MMDrawerBarButtonItem(target: self, action: "leftBarButtonPressed:")
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        tableViewTapRecognizer = UITapGestureRecognizer(target: self, action: "didTapTableView")
        
        chatManager.delegate = self
        updateUI()
        
        let token = NSUserDefaults.standardUserDefaults().stringForKey("AccessToken")
        if token == nil
        {
            let errorAlert = UIAlertView(title: "Notice", message: "It appears that you do not have a valid access token. Please login with your account under Settings.", delegate: nil, cancelButtonTitle: "Close")
            errorAlert.show()
        }
        else { chatManager.connect() }
        
        self.tableView.estimatedRowHeight = 22
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        self.sendMessageButton.enabled = false
    }
    
    func didTapTableView()
    {
        chatMessageTextField.resignFirstResponder()
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
                self.newMessageView.hidden = true
                // style it
                
                self.tableView.backgroundView = emptyStateLabel
            } else {
                self.tableView.backgroundView = nil
                self.rightButton.title = "Leave"
                self.newMessageView.hidden = false
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
    
    func keyboardWillShow(notification: NSNotification)
    {
        var info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey]as! NSValue).CGRectValue()
        self.bottomMargin.constant = CGRectGetHeight(keyboardFrame)
        tableView.addGestureRecognizer(tableViewTapRecognizer!)
    }
    
    func keyboardWillHide(notification: NSNotification)
    {
        self.bottomMargin.constant = 0
        tableView.removeGestureRecognizer(tableViewTapRecognizer!)
    }
    
    @IBAction func didPressSendButton()
    {
        let messageToSend = chatMessageTextField.text!
        chatManager.sendMessage(messageToSend)
        chatMessageTextField.text = ""
        sendMessageButton.enabled = false
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
        
        let chatMessage = chatMessages[indexPath.row]
        
        var sender = chatMessage.sender.componentsSeparatedByString("!")[0]
        sender = String(sender.characters.dropFirst())
        
        let messageLabel = cell?.viewWithTag(1) as! UILabel
        
        let attributedString = NSMutableAttributedString(string: sender + ": " + String(chatMessage.message.characters.dropLast()))
        
        let senderRange = NSMakeRange(0, sender.characters.count + 1)
        attributedString.beginEditing()
        if chatMessage.tags["color"] != nil && chatMessage.tags["color"]?.characters.count > 0
        {
            attributedString.addAttribute(NSForegroundColorAttributeName, value: UIColor(hex: chatMessage.tags["color"]!), range: senderRange)
        }
        attributedString.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(14), range: senderRange)
        attributedString.endEditing()
        
        messageLabel.attributedText = attributedString
        
        return cell!
    }
}

extension ChatViewController: IRCManagerDelegate
{
    func receivedChatMessage(message: ChatMessage)
    {
        if chatMessages.count == 60 { chatMessages.removeFirst() }
        chatMessages.append(message)
        self.tableView.reloadData()
        
        if(tableView.contentOffset.y >= (tableView.contentSize.height - tableView.frame.size.height))
        {
            let lastIndex = NSIndexPath(forRow: chatMessages.count - 1, inSection: 0)
            self.tableView.scrollToRowAtIndexPath(lastIndex, atScrollPosition: .Bottom, animated: false)
        }
    }
    
    func leftChannel()
    {
        chatMessages = []
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

extension ChatViewController: UITextFieldDelegate
{
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
    {
        if (string.characters.count > 0) { sendMessageButton.enabled = true }
        else { sendMessageButton.enabled = false }
        
        return true
    }
}