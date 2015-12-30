//
//  IRCManager.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 22-07-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

protocol IRCManagerDelegate
{
    func receivedChatMessage(message: ChatMessage)
}

class IRCManager
{
    static let sharedManager = IRCManager()
    private var connected = false
    private var socket: GCDAsyncSocket?
    var delegate: IRCManagerDelegate?
    private var readyToJoinChannel = false
    private var currentChannel = ""
    
    init()
    {
        socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
    }
    
    func connect()
    {
        var error: NSError?
        do {
            try socket!.connectToHost("irc.twitch.tv", onPort: 6667)
        } catch let error1 as NSError {
            error = error1
        }
        print("error: \(error)")
    }
    
    func disconnect()
    {
        socket!.disconnect()
    }
    
    func joinChannel(channelName: String)
    {
        let data = "JOIN #\(channelName)\n".dataUsingEncoding(NSUTF8StringEncoding)
        socket?.writeData(data, withTimeout: -1, tag: 0)
    }
    
    func leaveCurrentChannel()
    {
        let data = "PART #\(currentChannel)\n".dataUsingEncoding(NSUTF8StringEncoding)
        socket?.writeData(data, withTimeout: -1, tag: 0)
        currentChannel = ""
    }
    
    func handleChatMessage(message: ChatMessage)
    {
        if message.type == .Ping
        {
            let data = "PONG \(message.sender)\n".dataUsingEncoding(NSUTF8StringEncoding)
            socket?.writeData(data, withTimeout: -1, tag: 0)
        }
        else if message.code == "376"
        {
            readyToJoinChannel = true
        }
        else
        {
            delegate?.receivedChatMessage(message)
        }
    }
}

extension IRCManager: GCDAsyncSocketDelegate
{
    @objc func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16)
    {
        print("connected to Twitch IRC server")
        
        // authenticate
        let token = NSUserDefaults.standardUserDefaults().stringForKey("AccessToken")
        var data = "PASS oauth:\(token!)\n".dataUsingEncoding(NSUTF8StringEncoding)
        socket?.writeData(data, withTimeout: -1, tag: 0)
        
        data = "NICK devos50\n".dataUsingEncoding(NSUTF8StringEncoding)
        socket?.writeData(data, withTimeout: -1, tag: 0)
        
        socket?.readDataWithTimeout(-1, tag: 0)
    }
    
    @objc func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!)
    {
        print("Socket closed with error: \(err)")
    }
    
    @objc func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int)
    {
        let str = NSString(data: data, encoding: NSUTF8StringEncoding)
        if let message = str {
            let parts = message.componentsSeparatedByString("\n")
            for part in parts
            {
                if part.characters.count == 0 { continue }
                handleChatMessage(ChatMessage.parseMessage(part as String))
            }
        }
        
        socket?.readDataWithTimeout(-1, tag: 0)
    }
    
    
}