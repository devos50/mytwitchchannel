//
//  AdsNavigationController.swift
//  Mobile Streaming for Twitch
//
//  Created by Martijn de Vos on 02/01/16.
//  Copyright © 2016 martijndevos. All rights reserved.
//

import Foundation
import GoogleMobileAds

class AdsNavigationController: UINavigationController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        if NSUserDefaults.standardUserDefaults().boolForKey("EnableAds")
        {
            self.setToolbarHidden(false, animated: false)
            let adView = GADBannerView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, 50))
            self.toolbar.addSubview(adView)
            
            adView.adUnitID = AD_ID
            adView.rootViewController = self
            let request = GADRequest()
            request.testDevices = gadTestDevices
            adView.loadRequest(request)
        }
    }
}