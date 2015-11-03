//
//  StreamViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 09-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import UIKit
import MMDrawerController

class StreamViewController: UIViewController
{
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var fpsLabel: UILabel!
    var resolution: MPVideoResolution?
    var broadcastStreamClient: BroadcastStreamClient?
    let hostUrl = "rtmp://live-ams.twitch.tv:1935/app/"
    let orientation = AVCaptureVideoOrientation.Portrait
    var streamIsActive = false
    var memoryTicker: MemoryTicker?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        memoryTicker = MemoryTicker(responder: self, andMethod: "tickMemory:")
        
        let leftBarButtonItem = MMDrawerBarButtonItem(target: self, action: "leftBarButtonPressed:")
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
        
        resolution = RESOLUTION_VGA
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
    
    @IBAction func startButtonPressed()
    {
        if streamIsActive
        {
            disconnectStream()
        }
        else
        {
            broadcastStreamClient = BroadcastStreamClient(hostUrl, resolution: resolution!)
            broadcastStreamClient?.delegate = self
            broadcastStreamClient?.videoCodecId = MP_VIDEO_CODEC_H264
            broadcastStreamClient?.audioCodecId = MP_AUDIO_CODEC_AAC
            broadcastStreamClient?.setVideoOrientation(orientation)
            broadcastStreamClient?.stream("live_47555293_xC0hr682Ll20WZxv6AAtv4w6sUfRdr", publishType: PUBLISH_LIVE)
            streamIsActive = true
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
    
    func disconnectStream()
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
            disconnectStream()
        case CONN_CONNECTED:
            if description != MP_RTMP_CLIENT_IS_CONNECTED { break }
            broadcastStreamClient?.start()
        case STREAM_PAUSED:
            break
            // TODO
        case STREAM_PLAYING:
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
        disconnectStream()
        
        let errorAlertView = UIAlertView(title: "Error", message: "An error has occurred during the connection setup.", delegate: nil, cancelButtonTitle: "Close")
        errorAlertView.show()
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