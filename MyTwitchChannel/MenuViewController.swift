//
//  MenuViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 09-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import Foundation

class MenuViewController: UITableViewController
{
    
}

extension MenuViewController: UITableViewDataSource, UITableViewDelegate
{
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        var newNavigationController: UINavigationController? = nil;
        if indexPath.section == 0 && indexPath.row == 0
        {
            newNavigationController = self.storyboard?.instantiateViewControllerWithIdentifier("StreamNavigationController") as? UINavigationController
        }
        else if indexPath.section == 0 && indexPath.row == 1
        {
            newNavigationController = self.storyboard?.instantiateViewControllerWithIdentifier("SettingsNavigationController") as? UINavigationController
        }
        
        if(newNavigationController != nil)
        {
            self.mm_drawerController.setCenterViewController(newNavigationController!, withCloseAnimation: true, completion: nil)
        }
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    override func tableView(tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int)
    {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel.textColor = UIColor.blackColor()
    }
}