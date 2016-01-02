//
//  SettingsViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 09-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import UIKit
import Foundation
import SwiftyJSON
import MMDrawerController
import Alamofire
import ActionSheetPicker_3_0
import GoogleMobileAds

class SettingsViewController: UITableViewController
{
    @IBOutlet weak var accountNameLabel: UILabel!
    @IBOutlet weak var loginLogoutLabel: UILabel!
    @IBOutlet weak var streamQualityLabel: UILabel!
    @IBOutlet weak var streamOrientationLabel: UILabel!
    @IBOutlet weak var serverLabel: UILabel!
    @IBOutlet weak var adsSwitch: UISwitch!
    private var logoutAlertView: UIAlertView?
    private var streamServers = [JSON]()
    private var streamQualityPicker: ActionSheetStringPicker?
    private var streamOrientationPicker: ActionSheetStringPicker?
    private var streamServerPicker: ActionSheetStringPicker?
    private let streamQualities = ["Low", "Medium", "High"]
    private let streamOrientations = ["Portrait", "Landscape"]
    private var serversLoaded = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let leftBarButtonItem = MMDrawerBarButtonItem(target: self, action: "leftBarButtonPressed:")
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        
        logoutAlertView = UIAlertView(title: "Logout", message: "Are you sure that you want to logout?", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Logout")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadSettings", name: "com.martijndevos.MyTwitchChannel.ReloadSettings", object: nil)
        
        let streamQuality = NSUserDefaults.standardUserDefaults().stringForKey("StreamQuality")
        let streamOrientation = NSUserDefaults.standardUserDefaults().stringForKey("StreamOrientation")
        if streamQuality != nil { streamQualityLabel.text = streamQuality!.capitalizedString }
        if streamOrientation != nil { streamOrientationLabel.text = streamOrientation!.capitalizedString }
        
        let chosenServer = NSUserDefaults.standardUserDefaults().stringForKey("StreamServerName")
        if chosenServer == nil { serverLabel.text = "-" }
        else { serverLabel.text = chosenServer }
        
        adsSwitch.on = NSUserDefaults.standardUserDefaults().boolForKey("EnableAds")
        
        loadStreamServers()
        reloadSettings()
    }
    
    @IBAction func switchValueChanged(sender: UISwitch)
    {
        NSUserDefaults.standardUserDefaults().setBool(sender.on, forKey: "EnableAds")
        NSUserDefaults.standardUserDefaults().synchronize()
        (self.navigationController as? AdsNavigationController)?.loadAdsIfNeeded()
    }
    
    func leftBarButtonPressed(b: UIBarButtonItem)
    {
        self.mm_drawerController.toggleDrawerSide(.Left, animated: true, completion: nil)
    }
    
    func loadAccountName()
    {
        TwitchRequestManager.manager!.request(.GET, "https://api.twitch.tv/kraken/user")
            .responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            if result.isSuccess
            {
                var responseJSON = JSON(result.value!)
                self.accountNameLabel.text = responseJSON["name"].description
                NSUserDefaults.standardUserDefaults().setObject(responseJSON["name"].description, forKey: "TwitchUsername")
            }
        }
    }
    
    func reloadSettings()
    {
        let accessToken = NSUserDefaults.standardUserDefaults().stringForKey("AccessToken")
        if accessToken != nil
        {
            loginLogoutLabel.text = "Logout"
            loadAccountName()
        }
    }
    
    func loadStreamServers()
    {
        TwitchRequestManager.manager!.request(.GET, "https://api.twitch.tv/kraken/ingests", parameters: nil, encoding: ParameterEncoding.URL).responseJSON {
            (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            self.serversLoaded = true
            var responseJSON = JSON(result.value!)
            for server in responseJSON["ingests"] { self.streamServers.append(server.1) }
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return .LightContent
    }
    
    func showLoginPage()
    {
        let clientID = "qljlip4ir5oravauh8p49fwoddipw7d"
        let redirectURL = "http://auth.laureif80.eighty.axc.nl"
        
        let scopes = "user_read+user_blocks_edit+user_blocks_read+user_follows_edit+channel_read+channel_editor+channel_commercial+channel_stream+channel_subscriptions+user_subscriptions+channel_check_subscription+chat_login"
        let authURL = "https://api.twitch.tv/kraken/oauth2/authorize?response_type=token&client_id=\(clientID)&redirect_uri=\(redirectURL)&scope=\(scopes)"
        
        let nvc = self.storyboard?.instantiateViewControllerWithIdentifier("ShowWebsiteNavigationController") as! UINavigationController
        let vc = nvc.viewControllers[0] as! ShowWebsiteViewController
        vc.websiteURL = NSURL(string: authURL)!
        vc.pageTitle = "Login"
        
        self.navigationController?.presentViewController(nvc, animated: true, completion: nil)
    }
}

extension SettingsViewController : UIAlertViewDelegate
{
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int)
    {
        if alertView == logoutAlertView && buttonIndex == 1
        {
            NSUserDefaults.standardUserDefaults().setObject(nil, forKey: "AccessToken")
            loginLogoutLabel.text = "Login"
            accountNameLabel.text = "-"
        }
    }
}

extension SettingsViewController
{
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if indexPath.section == 1 && indexPath.row == 0 // login or logout
        {
            let accessToken = NSUserDefaults.standardUserDefaults().stringForKey("AccessToken")
            if accessToken != nil { logoutAlertView?.show() }
            else { showLoginPage() }
        }
        else if indexPath.section == 1 && indexPath.row == 1 // register
        {
            let nvc = self.storyboard?.instantiateViewControllerWithIdentifier("ShowWebsiteNavigationController") as! UINavigationController
            let vc = nvc.viewControllers[0] as! ShowWebsiteViewController
            vc.websiteURL = NSURL(string: "https://secure.twitch.tv/signup")!
            vc.pageTitle = "Register"
            self.navigationController?.presentViewController(nvc, animated: true, completion: nil)
        }
        else if indexPath.section == 2 && indexPath.row == 0 // quality stream picker
        {
            streamQualityPicker = ActionSheetStringPicker(title: "Select Quality", rows: streamQualities, initialSelection: 0, doneBlock: { (picker: ActionSheetStringPicker!, selectedIndex: Int, selectedValue: AnyObject!) -> Void in
                
                NSUserDefaults.standardUserDefaults().setObject(self.streamQualities[selectedIndex].lowercaseString, forKey: "StreamQuality")
                NSUserDefaults.standardUserDefaults().synchronize()
                self.streamQualityLabel.text = self.streamQualities[selectedIndex]
                
                }, cancelBlock: nil, origin: self.navigationController?.view)
            streamQualityPicker?.showActionSheetPicker()
        }
        else if indexPath.section == 2 && indexPath.row == 1 // orientation stream picker
        {
            streamOrientationPicker = ActionSheetStringPicker(title: "Select Orientation", rows: streamOrientations, initialSelection: 0, doneBlock: { (picker: ActionSheetStringPicker!, selectedIndex: Int, selectedValue: AnyObject!) -> Void in
                
                NSUserDefaults.standardUserDefaults().setObject(self.streamOrientations[selectedIndex].lowercaseString, forKey: "StreamOrientation")
                NSUserDefaults.standardUserDefaults().synchronize()
                self.streamOrientationLabel.text = self.streamOrientations[selectedIndex]
                
                }, cancelBlock: nil, origin: self.navigationController?.view)
            streamOrientationPicker?.showActionSheetPicker()
        }
        else if indexPath.section == 2 && indexPath.row == 2 // server stream picker
        {
            if !serversLoaded
            {
                let serverLoadingAlert = UIAlertView(title: "Notice", message: "The list with servers is still loading.", delegate: "nil", cancelButtonTitle: "Close")
                serverLoadingAlert.show()
                return
            }
            
            var streamServersTexts = [String]()
            for server in streamServers { streamServersTexts.append(server["name"].description) }
            
            streamServerPicker = ActionSheetStringPicker(title: "Select Server", rows: streamServersTexts, initialSelection: 0, doneBlock: { (picker: ActionSheetStringPicker!, selectedIndex: Int, selectedValue: AnyObject!) -> Void in
                
                NSUserDefaults.standardUserDefaults().setObject(self.streamServers[selectedIndex]["name"].description, forKey: "StreamServerName")
                NSUserDefaults.standardUserDefaults().setObject(self.streamServers[selectedIndex]["url_template"].description, forKey: "StreamServerURL")
                NSUserDefaults.standardUserDefaults().synchronize()
                self.serverLabel.text = streamServersTexts[selectedIndex]
                
                }, cancelBlock: nil, origin: self.navigationController?.view)
            streamServerPicker?.showActionSheetPicker()
        }
    }
}