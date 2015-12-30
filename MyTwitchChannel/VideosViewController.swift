//
//  VideosViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 01-07-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON
import Alamofire
import MMDrawerController
import SVProgressHUD

class VideosViewController: UITableViewController
{
    @IBOutlet weak var videoSearchBar: UISearchBar!
    var currentURL: String?
    var nextURL: String?
    var videos = [JSON]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        videoSearchBar.delegate = self
        
        let leftBarButtonItem = MMDrawerBarButtonItem(target: self, action: "leftBarButtonPressed:")
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
    }
    
    func loadVideosOfChannel(loadNext: Bool)
    {
        if !loadNext { videos = [] }
        SVProgressHUD.showWithStatus("Loading")
        TwitchRequestManager.manager!.request(.GET, loadNext ? nextURL! : currentURL!)
            .responseJSON { (request: NSURLRequest?, response: NSHTTPURLResponse?, result: Result<AnyObject>) in
            SVProgressHUD.dismiss()
            
            var responseJSON = JSON(result.value!)
            
            if responseJSON["status"].description == "422" || responseJSON["status"].description == "404"
            {
                let errorAlertView = UIAlertView(title: "Error", message: responseJSON["message"].description, delegate: nil, cancelButtonTitle: "Close")
                errorAlertView.show()
                return
            }
            
            self.nextURL = responseJSON["_links"]["next"].description
            for video in responseJSON["videos"] { self.videos.append(video.1) }
                
            self.tableView.reloadData()
        }
    }
    
    func leftBarButtonPressed(b: UIBarButtonItem)
    {
        self.mm_drawerController.toggleDrawerSide(.Left, animated: true, completion: nil)
    }
}

extension VideosViewController
{
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        if videos.count == 0 { return 0 }
        return videos.count + 1
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        if indexPath.section == 0 && indexPath.row == videos.count
        {
            var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("LoadMoreCell")
            if(cell == nil)
            {
                cell = UITableViewCell(style: .Default, reuseIdentifier: "LoadMoreCell")
            }
            return cell!
        }
        
        var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("VideoCell")
        if(cell == nil)
        {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "VideoCell")
        }
        
        let videoImageView = cell!.viewWithTag(1) as! UIImageView
        let videoNameLabel = cell!.viewWithTag(2) as! UILabel
        let videoDescriptionLabel = cell!.viewWithTag(3) as! UILabel
        let videoViewsLabel = cell!.viewWithTag(4) as! UILabel
        let videoDurationLabel = cell!.viewWithTag(5) as! UILabel
        let videoDescriptionLabel2 = cell!.viewWithTag(6) as! UILabel
        
        let video = videos[indexPath.row]
        print("video: \(video)")
        let videoPreview = video["preview"].description.stringByReplacingOccurrencesOfString("http://", withString: "https://")
        if let url = NSURL(string: videoPreview) {
            videoImageView.setImageWithURL(url)
        }
        
        videoNameLabel.text = video["title"].description
        videoDescriptionLabel.text = video["description"].description
        videoViewsLabel.text = video["views"].description
        videoDescriptionLabel2.text = video["channel"]["display_name"].description
        
        let videoDuration = Int(video["length"].description)!
        let minutes = videoDuration / 60
        let seconds = videoDuration % 60
        videoDurationLabel.text = "\(minutes):\(seconds)"
        
        return cell!
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        if indexPath.row == videos.count { return 54 }
        return 290
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        if indexPath.section == 0 && indexPath.row == videos.count
        {
            loadVideosOfChannel(true)
        }
        else
        {
            // open the VOD in the Twitch app
            let video = self.videos[indexPath.row]
            let url = "twitch://video/" + video["_id"].description
            if UIApplication.sharedApplication().canOpenURL(NSURL(string: url)!)
            {
                UIApplication.sharedApplication().openURL(NSURL(string: url)!)
            }
            else
            {
                let errorAlert = UIAlertView(title: "Twitch app", message: "The official Twitch app was not found. Please install it to view this VOD.", delegate: self, cancelButtonTitle: "Close")
                errorAlert.show()
            }
        }
    }
}

extension VideosViewController : UISearchBarDelegate
{
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        searchBar.resignFirstResponder()
        currentURL = "https://api.twitch.tv/kraken/channels/" + searchBar.text!.stringByReplacingOccurrencesOfString(" ", withString: "%20") + "/videos?limit=10"
        loadVideosOfChannel(false)
    }
}