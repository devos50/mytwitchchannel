//
//  ChatViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 22-07-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation
import Alamofire

class ChatViewController: UIViewController
{
    var chatManager = IRCManager.sharedManager
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        chatManager.connect()
    }
}