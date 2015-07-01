//
//  VideosViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 01-07-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation

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
            .responseJSON { (request, response, data, error) in
            SVProgressHUD.dismiss()
            println(data)
            
            var responseJSON = JSON(data!)
            
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

extension VideosViewController: UITableViewDataSource, UITableViewDelegate
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
            var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("LoadMoreCell") as? UITableViewCell
            if(cell == nil)
            {
                cell = UITableViewCell(style: .Default, reuseIdentifier: "LoadMoreCell")
            }
            return cell!
        }
        
        var cell : UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("VideoCell") as? UITableViewCell
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
        videoImageView.setImageWithURL(NSURL(string: video["preview"].description))
        videoNameLabel.text = video["title"].description
        videoDescriptionLabel.text = video["description"].description
        videoViewsLabel.text = video["views"].description
        videoDescriptionLabel2.text = video["channel"]["display_name"].description
        
        let videoDuration = video["length"].description.toInt()!
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
    }
}

extension VideosViewController : UISearchBarDelegate
{
    func searchBarSearchButtonClicked(searchBar: UISearchBar)
    {
        searchBar.resignFirstResponder()
        currentURL = "https://api.twitch.tv/kraken/channels/" + searchBar.text + "/videos?limit=10"
        loadVideosOfChannel(false)
    }
}