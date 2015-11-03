//
//  TwitchRequestManager.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 09-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation
import Alamofire

class TwitchRequestManager {
    
    static var manager: Manager?
    
    class func initializeManager()
    {
        var defaultHeaders = Manager.sharedInstance.session.configuration.HTTPAdditionalHeaders ?? [:]
        defaultHeaders["Accept"] = "application/vnd.twitchtv.v3+json"
        
        let accessToken = NSUserDefaults.standardUserDefaults().stringForKey("AccessToken")
        if accessToken != nil
        {
            defaultHeaders["Authorization"] = "OAuth \(accessToken!)"
        }
        
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = defaultHeaders
        manager = Manager(configuration: configuration)
    }
}