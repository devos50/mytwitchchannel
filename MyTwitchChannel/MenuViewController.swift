//
//  MenuViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 09-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation
import UIKit

class MenuViewController: UITableViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
    }
}

extension MenuViewController
{
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        var newNavigationController: UINavigationController? = nil;
        if indexPath.section == 0 && indexPath.row == 0
        {
            newNavigationController = self.storyboard?.instantiateViewControllerWithIdentifier("ChannelNavigationController") as? UINavigationController
        }
        else if indexPath.section == 0 && indexPath.row == 1
        {
            newNavigationController = self.storyboard?.instantiateViewControllerWithIdentifier("StreamNavigationController") as? UINavigationController
        }
        else if indexPath.section == 0 && indexPath.row == 2
        {
            newNavigationController = self.storyboard?.instantiateViewControllerWithIdentifier("VideosNavigationController") as? UINavigationController
        }
        else if indexPath.section == 0 && indexPath.row == 3
        {
            newNavigationController = self.storyboard?.instantiateViewControllerWithIdentifier("ChatNavigationController") as? UINavigationController
        }
        else if indexPath.section == 0 && indexPath.row == 4
        {
            newNavigationController = self.storyboard?.instantiateViewControllerWithIdentifier("AccountNavigationController") as? UINavigationController
        }
        else if indexPath.section == 0 && indexPath.row == 5
        {
            newNavigationController = self.storyboard?.instantiateViewControllerWithIdentifier("SettingsNavigationController") as? UINavigationController
        }
        else if indexPath.section == 0 && indexPath.row == 6
        {
            newNavigationController = self.storyboard?.instantiateViewControllerWithIdentifier("FeedbackNavigationController") as? UINavigationController
        }
        
        if(newNavigationController != nil)
        {
            self.mm_drawerController.setCenterViewController(newNavigationController!, withCloseAnimation: true, completion: nil)
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    {
        return CGFloat.min
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel!.textColor = UIColor.blackColor()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 44
    }
    
    override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return 44
    }
}