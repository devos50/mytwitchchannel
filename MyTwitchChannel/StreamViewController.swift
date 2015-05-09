//
//  StreamViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 09-05-15.
//  Copyright (c) 2015 martijndevos. All rights reserved.
//

import UIKit

class StreamViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let leftBarButtonItem = MMDrawerBarButtonItem(target: self, action: "leftBarButtonPressed:")
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
    }
    
    func leftBarButtonPressed(b: UIBarButtonItem)
    {
        self.mm_drawerController.toggleDrawerSide(.Left, animated: true, completion: nil)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return .LightContent
    }
}

