//
//  SettingsViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 09-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation

class SettingsViewController: UITableViewController
{
    @IBOutlet weak var accountNameLabel: UILabel!
    @IBOutlet weak var loginLogoutLabel: UILabel!
    @IBOutlet weak var serverLabel: UILabel!
    var logoutAlertView: UIAlertView?
    var streamServers = [JSON]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let leftBarButtonItem = MMDrawerBarButtonItem(target: self, action: "leftBarButtonPressed:")
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        
        logoutAlertView = UIAlertView(title: "Logout", message: "Are you sure that you want to logout?", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Logout")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "reloadSettings", name: "com.martijndevos.MyTwitchChannel.ReloadSettings", object: nil)
        
        loadStreamServers()
        reloadSettings()
    }
    
    func leftBarButtonPressed(b: UIBarButtonItem)
    {
        self.mm_drawerController.toggleDrawerSide(.Left, animated: true, completion: nil)
    }
    
    func loadAccountName()
    {
        TwitchRequestManager.manager!.request(.GET, "https://api.twitch.tv/kraken/user")
            .responseJSON { (request, response, data, error) in
                var responseJSON = JSON(data!)
                self.accountNameLabel.text = responseJSON["name"].description
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
            (request, response, data, error) in
            var responseJSON = JSON(data!)
            for server in responseJSON["ingests"] { self.streamServers.append(server.1) }
            self.serverLabel.text = self.streamServers[0]["name"].description
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return .LightContent
    }
    
    func showLoginPage()
    {
        let clientID = "qljlip4ir5oravauh8p49fwoddipw7d"
        let clientSecret = "3ecsp5prgbercz631uiamj7dkgrofue"
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
        }
    }
}

extension SettingsViewController : UITableViewDelegate
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
    }
}