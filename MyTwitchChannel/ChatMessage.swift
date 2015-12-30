//
//  ChatMessage.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 03-10-15.
//  Copyright © 2015 martijndevos. All rights reserved.
//

import Foundation

enum ChatMessageType
{
    case TextMessage, Ping
}

class ChatMessage
{
    var sender: String
    var message: String
    var code: String
    var type: ChatMessageType = .TextMessage
    
    init(code: String, sender: String, message: String, type: ChatMessageType)
    {
        self.sender = sender
        self.message = message
        self.code = code
        self.type = type
    }
    
    class func parseMessage(text: String) -> ChatMessage
    {
        let parts = text.componentsSeparatedByString(" ")
        
        if parts[0] == "PING" { return ChatMessage(code: "", sender: parts[1], message: "", type: .Ping) }
        
        print("text: \(text)")
        
        var message = ""
        if parts.count > 3
        {
            for i in 3...parts.count-1
            {
                print("appending \(parts[i])")
                message += parts[i] + " "
            }
        }
        message = String(message.characters.dropLast())
        
        return ChatMessage(code: parts[1], sender: parts[2], message: message, type: .TextMessage)
    }
}