//
//  ShowWebsiteViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 09-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation

class ShowWebsiteViewController: UIViewController
{
    @IBOutlet weak var websiteView: UIWebView!
    var websiteURL: NSURL?
    var pageTitle: String?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if pageTitle != nil { self.title = pageTitle! }
        websiteView.loadRequest(NSURLRequest(URL: websiteURL!))
        websiteView.delegate = self
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return .LightContent
    }
    
    @IBAction func closePressed()
    {
        self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

extension ShowWebsiteViewController : UIWebViewDelegate
{
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool
    {
        let url = request.URL!.absoluteString
        if startsWith(url!, "http://auth.laureif80.eighty.axc.nl")
        {
            // captured login attempt
            var parts = url!.componentsSeparatedByString("=")
            parts = parts[1].componentsSeparatedByString("&")
            
            NSUserDefaults.standardUserDefaults().setObject(parts[0], forKey: "AccessToken")
            NSNotificationCenter.defaultCenter().postNotificationName("com.martijndevos.MyTwitchChannel.ReloadSettings", object: nil)
            
            self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            
            return false
        }
        
        return true
    }
}