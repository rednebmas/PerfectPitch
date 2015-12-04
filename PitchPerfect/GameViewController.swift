//
//  GameViewController.swift
//  PitchPerfect
//
//  Created by Sam Bender on 11/23/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import UIKit

class GameViewController: UIViewController, GameDelegate {
    
    // MARK: Properties 
    
    @IBOutlet weak var noteButton: UIButton!
    @IBOutlet weak var nextNoteLabel: UILabel!
    @IBOutlet weak var currentNoteLabel: UILabel!
    @IBOutlet weak var previousNoteLabel: UILabel!
    
    var song : Song = Song()
    lazy var game: Game = Game(song: Song())
    
    // MARK: View controller lifecycle
    
    struct defaultKeys {
        static let localStorageKey = "LocalStorageKey"
    }
    
    var songArray : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.game = Game(song: song)
        self.game.delegate = self
        
        noteButton.layer.borderWidth = 2
        noteButton.layer.borderColor = UIColor(white: 1.0, alpha: 100).CGColor
        
        game.start()
        
        self.noteButton.addTarget(self, action: "replay", forControlEvents: .TouchUpInside)
        previousNoteLabel.text = "pNote"
        currentNoteLabel.text = "cNote"
        nextNoteLabel.text = "nNote"
        //
        // Simple example of how to play just one note
        //
        
        /*
        
        let note = Note(noteName: "A4", duration: 1.0)
        note.play() // plays until stop() is called
        // or
        note.playForDuration()
        
        */
        songArray.append(song.title)
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(songArray, forKey: defaultKeys.localStorageKey) //storing the content
        defaults.synchronize()
        print("localStorage woohoo")
        print(defaults.valueForKey(defaultKeys.localStorageKey))
    }
    
    func replay() {
        self.game.song?.playCurrentNote()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.game.stop()
    }
    
    func noteWasUpdated(note: Note?) {
        dispatch_async(dispatch_get_main_queue(), {
            // UIView.setAnimationsEnabled(false)
            if note != nil {
                self.noteButton.setTitle(note!.nameWithoutOctave, forState: .Normal)
                // self.progressView.setProgress(Float((note?.percentCompleted)!), animated: true)
            } else {
                self.noteButton.setTitle("--", forState: .Normal)
                // self.progressView.setProgress(0.0, animated: false)
            }
            
            // self.currentButton.setTitle(self.game.song?.currentNote?.nameWithoutOctave, forState: .Normal)
            // UIView.setAnimationsEnabled(true)
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "GameOverSegue" {
            if let controller = segue.destinationViewController as? GameOverViewController {
                controller.songTitle = song.title
            }
        }
    }
}
