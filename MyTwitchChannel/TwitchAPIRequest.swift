//
//  TwitchAPIRequest.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 09-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation

class TwitchAPIRequest
{
    class func getRequest(endpoint: String) -> URLRequestConvertible
    {
        let URL = NSURL(string: "https://api.twitch.tv/kraken/" + endpoint)!
        let mutableURLRequest = NSMutableURLRequest(URL: URL)
        mutableURLRequest.HTTPMethod = "GET"
        
        var JSONSerializationError: NSError? = nil
        mutableURLRequest.HTTPBody = NSJSONSerialization.dataWithJSONObject([], options: nil, error: &JSONSerializationError)
        mutableURLRequest.setValue("application/vnd.twitchtv.v3+json", forHTTPHeaderField: "Accept")
        
        return mutableURLRequest
    }
}