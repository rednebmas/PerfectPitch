//
//  GameOverViewController.swift
//  PitchPerfect
//
//  Created by Megan Hodge on 12/1/15.
//  Copyright © 2015 Sam Bender. All rights reserved.

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
        if song == nil {
            print("Song was nil")
            return
        }
        
        print("song.currentscore = " + (song?.currentScore!.description)!)
        self.scoreLabel.text = String(self.song!.currentScore!)
        song!.scores!.append(self.song!.currentScore!)
        song!.highScore! = max(song!.highScore!, self.song!.currentScore!)
        let songs = Songs.shardInstance
        songs.saveSong(song!)
        //Todo Add HighSchore
        self.bestScoreLabel.text = String(song!.highScore!)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "highScoreSegue" {
            if let controller = segue.destinationViewController as? ScoresTableViewController {
            }
        } else if segue.identifier == "tryAgainSegue" {
            if let controller = segue.destinationViewController as? GameViewController {
                controller.game.song! = self.song!
                controller.game.song!.currentNoteIndex = 0
            }
        } else { //segue.identifier == "homeSegue"
            if let controller = segue.destinationViewController as? ViewController {
            }
        }
    }

    @IBAction func shareScore(sender: AnyObject) {
        let items = ["I just played \(self.song!.title) and got the score \(self.song!.currentScore!)/100."]
        let activityView = UIActivityViewController.init(activityItems: items, applicationActivities: nil)
        self.presentViewController(activityView, animated: true, completion: nil)
    }
    
    func storingScores() {
        
    }

}
