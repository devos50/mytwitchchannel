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
    case TextMessage, Ping, Other, Join
}

class ChatMessage
{
    var sender: String
    var message: String
    var code: String
    var type: ChatMessageType = .Other
    var tags: [String : String]
    
    init(code: String, sender: String, message: String, type: ChatMessageType, tags: [String : String])
    {
        self.sender = sender
        self.message = message
        self.code = code
        self.type = type
        self.tags = tags
    }
    
    class func parseMessage(text: String) -> ChatMessage
    {
        let parts = text.componentsSeparatedByString(" ")
        
        // print("text: \(text)")
        
        if parts[0] == "PING" { return ChatMessage(code: "", sender: parts[1], message: "", type: .Ping, tags: [String: String]()) }
        if parts.count > 0 && parts[1] == "JOIN" { return ChatMessage(code: "", sender: parts[1], message: "", type: .Join, tags: [String: String]()) }
        
        var message = ""
        if parts.count > 4
        {
            for i in 4...parts.count-1
            {
                var partToAppend = parts[i]
                if i == 4 && parts[i].characters.count > 0 && parts[i].hasPrefix(":")
                {
                    // strip the first : from the front
                    partToAppend = String(parts[i].characters.dropFirst())
                }
                message += partToAppend + " "
            }
        }
        message = String(message.characters.dropLast())
        
        let type: ChatMessageType = (parts[2] == "PRIVMSG") ? .TextMessage : .Other
        
        var tags = [String : String]()
        if type == .TextMessage
        {
            // parse the tags
            let tagparts = String(parts[0].characters.dropFirst()).componentsSeparatedByString(";")
            for tagpart in tagparts
            {
                let parts2 = tagpart.componentsSeparatedByString("=")
                if parts2.count != 2 { continue }
                tags[parts2[0]] = parts2[1]
            }
        }
        
        return ChatMessage(code: parts[2], sender: parts[1], message: message, type: type, tags: tags)
    }
}