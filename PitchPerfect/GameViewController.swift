//
//  GameViewController.swift
//  PitchPerfect
//
//  Created by Sam Bender on 11/23/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import UIKit
import Spring

class GameViewController: UIViewController, GameDelegate {
    
    // MARK: Properties 
    
    @IBAction func endGameButton(sender: AnyObject) {
        performSegueWithIdentifier("GameOverSegue", sender: sender)
    }
    @IBOutlet weak var noteButton: UIButton!
    @IBOutlet weak var nextNoteLabel: DesignableLabel!
    @IBOutlet weak var currentNoteLabel: DesignableLabel!
    @IBOutlet weak var previousNoteLabel: DesignableLabel!
    @IBOutlet weak var noteProgressView: UIProgressView!
    @IBOutlet weak var noteHigherLabel: UILabel!
    
    @IBOutlet weak var pitchLowProgressView: UIProgressView!
    @IBOutlet weak var pitchHighProgressView: UIProgressView!
    @IBOutlet weak var noteLowerLabel: UILabel!
    var song : Song = Song(title: "")
    lazy var game: Game = Game(song: Song(title: ""))
    
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
        
        let songNotes = song.notes
        
        previousNoteLabel.text = ""
        currentNoteLabel.text = songNotes![0].nameWithoutOctave
        nextNoteLabel.text = songNotes![1].nameWithoutOctave
        //
        // Simple example of how to play just one note
        //
        
        /*
        
        let note = Note(noteName: "A4", duration: 1.0)
        note.play() // plays until stop() is called
        // or
        note.playForDuration()
        
        */
//        songArray.append(song.title)
//        let defaults = NSUserDefaults.standardUserDefaults()
//        defaults.setValue(songArray, forKey: defaultKeys.localStorageKey) //storing the content
//        defaults.synchronize()
//        print("localStorage woohoo")
//        print(defaults.valueForKey(defaultKeys.localStorageKey))
    }
    
    func replay() {
        self.game.song?.playCurrentNote()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.game.stop()
    }
    
    
    @IBAction func skipNotePressed(sender: AnyObject) {
        self.game.nextNote(true)
    }
    
    @IBAction func endGamePressed(sender: AnyObject) {
    
    }
    
    func pitchWasUpdated(note: Note?) {
        dispatch_async(dispatch_get_main_queue(), {
            UIView.setAnimationsEnabled(false)
            if note != nil {
                if self.game.currentState == Game.State.Waiting {
                    self.noteButton.layer.borderColor = UIColor(white: 1.0, alpha: 100).CGColor

                    //frequency will never be = when the game state is in waiting
                    if note!.frequency > self.game.song!.currentNote!.frequency {
                        self.noteHigherLabel.textColor = UIColor(red: 0.17647059, green: 1, blue: 1, alpha: 1)
                        self.noteLowerLabel.textColor = UIColor.whiteColor()
                        self.noteLowerLabel.hidden = true
                        self.noteHigherLabel.hidden = false
                    } else {
                        self.noteHigherLabel.textColor = UIColor.whiteColor()
                        self.noteHigherLabel.hidden = true
                        self.noteLowerLabel.hidden = false
                        self.noteLowerLabel.textColor = UIColor(red: 0.17647059, green: 1, blue: 1, alpha: 1)
                    }
                    
                } else if self.game.currentState == Game.State.Detecting {
                    self.noteButton.layer.borderColor = UIColor.greenColor().CGColor
                    // self.noteHigherLabel.textColor = UIColor.whiteColor()
                    // self.noteLowerLabel.textColor = UIColor.whiteColor()
                    self.noteHigherLabel.hidden = true
                    self.noteLowerLabel.hidden = true
                    
                }
                self.noteButton.setTitle(note!.nameWithoutOctave, forState: .Normal)
                self.noteProgressView.setProgress(Float((note?.percentCompleted)!), animated: true)
                
                // update progress bars
                let diffInCents = note!.differenceInCentsToNote(self.game.song!.currentNote!)
                if diffInCents > 0 {
                    let progress = Float(diffInCents / 50.0)
                    self.pitchLowProgressView.progress = 1.0
                    self.pitchHighProgressView.progress = progress < 1 ? progress : 1
                } else {
                    let progress = Float(diffInCents / -50.0)
                    self.pitchLowProgressView.progress = progress < 1 ? 1 - progress : 0
                    self.pitchHighProgressView.progress = 0.0
                }
                
            } else { // note is nil
                self.noteButton.layer.borderColor = UIColor(white: 1.0, alpha: 100).CGColor
                self.noteButton.setTitle("--", forState: .Normal)
                self.noteProgressView.setProgress(0.0, animated: false)
            }
            // self.currentButton.setTitle(self.game.song?.currentNote?.nameWithoutOctave, forState: .Normal)
            UIView.setAnimationsEnabled(true)
            
        })
        
    }
    
    func gameOver() {
        print("Score \(self.game.score)")
    }
    
    func noteWasUpdated(note: Note?) {
        dispatch_async(dispatch_get_main_queue(), {
            
            UIView.setAnimationsEnabled(false)
            if self.game.song != nil {

                let updateNoteUI = {
                    (note: Note?, label: DesignableLabel) in
                    if note != nil {
                        label.text = note!.nameWithoutOctave
                    } else {
                        label.text = "-"
                    }
                    label.animation = "slideLeft"
                    label.curve = "easeIn"
                    label.duration = 1.0
                }
                updateNoteUI(self.game.song!.previousNote, self.previousNoteLabel)
//                updateNoteUI(self.game.song!.currentNote, self.currentNoteLabel)
                updateNoteUI(self.game.song!.nextNote, self.nextNoteLabel)
            }
            UIView.setAnimationsEnabled(true)
            self.nextNoteLabel.animation = "slideLeft"
            self.nextNoteLabel.animate()
            
            self.currentNoteLabel.animation = "pop"
//            self.currentNoteLabel.delay = 0
            self.currentNoteLabel.animateToNext({ () -> () in
                self.currentNoteLabel.text = self.game.song!.currentNote?.nameWithoutOctave
            })
            self.previousNoteLabel.animation = "fadeOut"
            self.previousNoteLabel.duration = 1.5
            self.previousNoteLabel.animate()
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
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}
