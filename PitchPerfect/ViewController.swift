//
//  ViewController.swift
//  PitchPerfect
//
//  Created by Sam Bender on 11/23/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Constants.PITCH_PERFECT_COLOR
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func didSelectSettings(sender: AnyObject) {
        
        let settingsVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SettingsViewController") as! SettingsViewController
        settingsVC.modalPresentationStyle = .OverCurrentContext
        settingsVC.modalTransitionStyle = .CrossDissolve
//        settingsVC.delegate = self
        self.presentViewController(settingsVC, animated: false, completion: nil)
        
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}

