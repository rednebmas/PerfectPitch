//
//  GameOverViewController.swift
//  PitchPerfect
//
//  Created by Megan Hodge on 12/1/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import UIKit

class GameOverViewController: UIViewController {
    var song : Song?
    
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var bestScoreLabel: UILabel!
    
    struct defaultKeys {
        static let localStorageKey = "LocalStorageKey"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.songTitleLabel.text = song?.title
        
//        let defaults = NSUserDefaults.standardUserDefaults()
//        defaults.setValue(songScoreDictionary, forKey: defaultKeys.localStorageKey) //storing the content
//        defaults.synchronize()
        self.bestScoreLabel.text = String(song?.highScore)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    func storingScores() {
        
    }

}
