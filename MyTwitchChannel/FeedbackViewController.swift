//
//  FeedbackViewController.swift
//  MyTwitchChannel
//
//  Created by Martijn de Vos on 30/12/15.
//  Copyright © 2015 martijndevos. All rights reserved.
//

import Foundation
import ActionSheetPicker_3_0
import Alamofire
import SVProgressHUD
import MMDrawerController

class FeedbackViewController: UITableViewController
{
    @IBOutlet weak var feedbackRegardingLabel: UILabel!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var feedbackTextView: UITextView!
    private var feedbackRegardingPicker: ActionSheetStringPicker?
    private var selectedFeedbackIndex = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let regardingFeedbackChoices = ["Improvement", "New feature", "Bug"]
        feedbackRegardingPicker = ActionSheetStringPicker(title: "Feedback regarding", rows: regardingFeedbackChoices, initialSelection: 0, doneBlock: { (picker: ActionSheetStringPicker!, selectedIndex: Int, selectedValue: AnyObject!) -> Void in
            
            self.selectedFeedbackIndex = selectedIndex
            self.feedbackRegardingLabel.text = regardingFeedbackChoices[selectedIndex]
            
        }, cancelBlock: nil, origin: self.navigationController?.view)
        
        let leftBarButtonItem = MMDrawerBarButtonItem(target: self, action: "leftBarButtonPressed:")
        self.navigationItem.leftBarButtonItem = leftBarButtonItem
    }
    
    func leftBarButtonPressed(b: UIBarButtonItem)
    {
        self.mm_drawerController.toggleDrawerSide(.Left, animated: true, completion: nil)
    }
    
    @IBAction func sendButtonPressed()
    {
        if titleTextField.text?.characters.count == 0
        {
            showErrorAlert("Please fill in the title of your feedback.")
        }
        else if feedbackTextView.text?.characters.count == 0
        {
            showErrorAlert("Please fill in your feedback.")
        }
        else
        {
            sendFeedbackForm()
        }
    }
    
    func sendFeedbackForm()
    {
        SVProgressHUD.showWithStatus("Sending feedback")
        
        Alamofire.request(.POST, "http://laureif80.eighty.axc.nl/mtc/mstissue", parameters: ["title" : titleTextField.text!, "body" : feedbackTextView.text, "ios" : true, "type" : "\(selectedFeedbackIndex)"]).response { (request: NSURLRequest?, response: NSHTTPURLResponse?, data: NSData?, error: ErrorType?) -> Void in
            
            SVProgressHUD.dismiss()
            
            let successAlert = UIAlertView(title: "Success", message: "Your feedback has been received.", delegate: nil, cancelButtonTitle: "Close")
            successAlert.show()
            self.titleTextField.text = ""
            self.feedbackTextView.text = ""
        }
    }
    
    func showErrorAlert(text: String)
    {
        let errorAlert = UIAlertView(title: "Notice", message: text, delegate: nil, cancelButtonTitle: "Close")
        errorAlert.show()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        if indexPath.section == 1 && indexPath.row == 0
        {
            feedbackRegardingPicker?.showActionSheetPicker()
        }
    }
}