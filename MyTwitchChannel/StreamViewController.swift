//
//  StreamViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 09-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import UIKit
import MMDrawerController
import SVProgressHUD
import Alamofire
import SwiftyJSON

class StreamViewController: UIViewController
{
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var fpsLabel: UILabel!
    @IBOutlet weak var rightBarButton: UIBarButtonItem!
    private var resolution: MPVideoResolution?
    var broadcastStreamClient: BroadcastStreamClient?
    private var orientation = AVCaptureVideoOrientation.Portrait
    private var streamIsActive = false
    private var memoryTicker: MemoryTicker?
    private var streamKey: String?
    private var attemptsDone = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        memoryTicker = MemoryTicker(responder: self, andMethod: "tickMemory:")
        
        let leftBarButtonItem = MMDrawerBarButtonItem(target: self, action: "leftBarButtonPressed:")
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        
        let chosenOrientation = NSUserDefaults.standardUserDefaults().stringForKey("StreamOrientation")
        if chosenOrientation == "landscape" { orientation = AVCaptureVideoOrientation.LandscapeLeft }
        
        let chosenQuality = NSUserDefaults.standardUserDefaults().stringForKey("StreamQuality")
        if chosenQuality == "low" { resolution = RESOLUTION_LOW }
        else if chosenQuality == "medium" { resolution = RESOLUTION_MEDIUM }
        else { resolution = RESOLUTION_VGA }
        
        // check if you should select a server
        if NSUserDefaults.standardUserDefaults().stringForKey("StreamServerName") == nil
        {
            let errorAlert = UIAlertView(title: "Notice", message: "It appears that you have not selected a preferred Twitch server. Please do so in the Settings menu.", delegate: nil, cancelButtonTitle: "Close")
            errorAlert.show()
            rightBarButton.enabled = false
        }
    }
    
    func tickMemory(num: NSNumber)
    {
        if broadcastStreamClient == nil { fpsLabel.text = "FPS: -" }
        else { fpsLabel.text = "FPS: \(round(broadcastStreamClient!.getMeanFPS()))" }
    }
    
    func leftBarButtonPressed(b: UIBarButtonItem)
    {
        self.mm_drawerController.toggleDrawerSide(.Left, animated: true, completion: nil)
    }
    
    func fetchStreamKey()
    {
        TwitchRequestManager.manager!.request(.GET, "https://api.twitch.tv/kraken/channel").responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            if result.isSuccess {
                var responseJSON = JSON(result.value!)
                
                print(responseJSON)
                
                if responseJSON["status"] == 401 {
                    let errorAlertView = UIAlertView(title: "Error", message: "You are unauthorized to make this call. Try to logout and login with your account under Settings.", delegate: nil, cancelButtonTitle: "Close")
                    errorAlertView.show()
                    
                    SVProgressHUD.dismiss()
                    
                    return
                }
                
                self.streamKey = responseJSON["stream_key"].description
                print("Stream key: \(self.streamKey)")
                self.startStream()
            }
            else {
                let errorAlertView = UIAlertView(title: "Error", message: "An unknown error has occurred. Please try again.", delegate: nil, cancelButtonTitle: "Close")
                errorAlertView.show()
                
                SVProgressHUD.dismiss()
            }
        }
    }
    
    func startStream()
    {
        var serverUrl = NSUserDefaults.standardUserDefaults().stringForKey("StreamServerURL")!
        serverUrl = serverUrl.stringByReplacingOccurrencesOfString("{stream_key}", withString: "")
        print("server url: \(serverUrl)")
        
        broadcastStreamClient = BroadcastStreamClient(serverUrl, resolution: resolution!)
        broadcastStreamClient?.delegate = self
        broadcastStreamClient?.videoCodecId = MP_VIDEO_CODEC_H264
        broadcastStreamClient?.audioCodecId = MP_AUDIO_CODEC_AAC
        broadcastStreamClient?.setVideoOrientation(orientation)
        broadcastStreamClient?.stream(streamKey, publishType: PUBLISH_LIVE)
        streamIsActive = true
    }
    
    @IBAction func startButtonPressed()
    {
        if streamIsActive
        {
            doDisconnect()
        }
        else
        {
            SVProgressHUD.showWithStatus("Starting stream")
            if streamKey != nil { startStream() }
            else { fetchStreamKey() }
        }
    }
    
    @IBAction func changeCamera()
    {
        if broadcastStreamClient == nil || broadcastStreamClient!.state != STREAM_PLAYING { return }
        broadcastStreamClient?.switchCameras()
        
        // send camera change metadata
        let camera = broadcastStreamClient!.isUsingFrontFacingCamera ? "FRONT" : "BACK"
        let date = NSDate()
        let meta = ["camera" : camera, "date" : date.description]
        broadcastStreamClient?.sendMetadata(meta, event: "changedCamera:")
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return .LightContent
    }
    
    func doDisconnect()
    {
        broadcastStreamClient?.disconnect()
    }
    
    func setDisconnect()
    {
        broadcastStreamClient?.teardownPreviewLayer()
        broadcastStreamClient = nil
        streamIsActive = false
        self.navigationItem.rightBarButtonItem!.title = "Start"
    }
}

extension StreamViewController: MPIMediaStreamEvent
{
    func stateChanged(sender: AnyObject!, state: MPMediaStreamState, description: String!)
    {
        print("State changed -> \(state)")
        switch state
        {
        case CONN_DISCONNECTED:
            setDisconnect()
        case CONN_CONNECTED:
            if description != MP_RTMP_CLIENT_IS_CONNECTED { break }
            broadcastStreamClient?.start()
        case STREAM_PAUSED:
            break
            // TODO
        case STREAM_PLAYING:
            attemptsDone = 0
            SVProgressHUD.dismiss()
            streamIsActive = true
            broadcastStreamClient?.setPreviewLayer(previewView)
            self.navigationItem.rightBarButtonItem!.title = "Stop"
        default:
            break
        }
    }
    
    func connectFailed(sender: AnyObject!, code: Int32, description: String!)
    {
        print("Connect failed: \(description)")
        if broadcastStreamClient == nil { return }
        setDisconnect()
        
        if code == -7 && attemptsDone < 5 // just retry...
        {
            attemptsDone++
            startStream()
        }
        else
        {
            SVProgressHUD.dismiss()
            let errorAlertView = UIAlertView(title: "Error", message: "An error has occurred during the connection setup.", delegate: nil, cancelButtonTitle: "Close")
            errorAlertView.show()
        }
        
        
    }
    
    func pixelBufferShouldBePublished(pixelBuffer: CVPixelBuffer!, timestamp: Int32)
    {
        let frameBuffer = pixelBuffer
        
        let bufferSize = CVPixelBufferGetDataSize(frameBuffer)
        
        let width = CVPixelBufferGetWidth(frameBuffer)
        let height = CVPixelBufferGetHeight(frameBuffer)
        
        broadcastStreamClient?.sendMetadata(["videoTimestamp" : NSNumber(int: timestamp), "bufferSize" : NSNumber(integer: bufferSize), "width: " : NSNumber(integer: width), "height" : NSNumber(integer: height)], event: "videoFrameOptions:")
    }
}