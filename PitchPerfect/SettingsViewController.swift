//
//  SettingsViewController.swift
//  PerfectPitch
//
//  Created by blankens on 12/8/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import UIKit
import Spring

class SettingsViewController: UIViewController {

    @IBOutlet weak var settingsView: DesignableView!
    
    @IBAction func didSelectBackground(sender: AnyObject) {
        settingsView.animation = "zoomOut"
        settingsView.animate()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}