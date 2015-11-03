//
//  ChatMessage.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 03-10-15.
//  Copyright © 2015 martijndevos. All rights reserved.
//

import Foundation

class ChatMessage
{
    var sender: String
    var message: String
    
    init(sender: String, message: String)
    {
        self.sender = sender
        self.message = message
    }
}