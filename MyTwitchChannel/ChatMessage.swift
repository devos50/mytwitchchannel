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
    case TextMessage, Ping, Other
}

class ChatMessage
{
    var sender: String
    var message: String
    var code: String
    var type: ChatMessageType = .Other
    
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
                var partToAppend = parts[i]
                if i == 3 && parts[i].characters.count > 0 && parts[i].hasPrefix(":")
                {
                    // strip the first : from the front
                    partToAppend = String(parts[i].characters.dropFirst())
                }
                message += partToAppend + " "
            }
        }
        message = String(message.characters.dropLast())
        
        let type: ChatMessageType = (parts[1] == "PRIVMSG") ? .TextMessage : .Other
        
        return ChatMessage(code: parts[1], sender: parts[2], message: message, type: type)
    }
}