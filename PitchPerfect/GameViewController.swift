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
        performSegueWithIdentifier("GameOverSegue", sender: self)
    }
    @IBOutlet weak var noteButton: UIButton!
    @IBOutlet weak var nextNoteLabel: DesignableLabel!
    @IBOutlet weak var currentNoteLabel: DesignableLabel!
    @IBOutlet weak var previousNoteLabel: DesignableLabel!
    @IBOutlet weak var noteProgressView: UIProgressView!
    @IBOutlet weak var noteHigherLabel: UILabel!
    
    @IBOutlet weak var score: UILabel!
    @IBOutlet weak var pitchLowProgressView: UIProgressView!
    @IBOutlet weak var pitchHighProgressView: UIProgressView!
    @IBOutlet weak var noteLowerLabel: UILabel!
    lazy var game: Game = Game(song: Song(title: ""))
    // MARK: View controller lifecycle
    
    @IBOutlet weak var skipNoteButton: DesignableButton!
    struct defaultKeys {
        static let localStorageKey = "LocalStorageKey"
    }
    
    var songArray : [String] = []
    var noteByNote = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !noteByNote {
            skipNoteButton.hidden = true
        }
        
        
//        self.game = Game(song: song)
        self.game.delegate = self
        self.game.song!.restart()
//        noteButton.layer.borderWidth = 2
//        noteButton.layer.borderColor = UIColor(white: 1.0, alpha: 100).CGColor
        
        currentNoteLabel.layer.borderWidth = 2
        currentNoteLabel.layer.borderColor = UIColor(white: 1.0, alpha: 100).CGColor

        
        print("game.mode = \(game.mode)")
        game.start()
        
        // For continous playback, the successful song note duration is longer than the 
        // autoplay length per note, so the "continous" gameplay isn't working right now
        // as you don't have time to "hit" the note before it moves on to the next note
        
        // Continuous gameplay mode start
        
        if !noteByNote {
            game.song?.play()
        }
        
        
        if self.game.song?.currentScore == nil {
           self.game.song?.currentScore = 0
        }
        
        self.noteButton.addTarget(self, action: "replay", forControlEvents: .TouchUpInside)
        
        let songNotes = self.game.song!.notes
        
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
    
    func pitchWasUpdated(note: Note?) {
        dispatch_async(dispatch_get_main_queue(), {
            UIView.setAnimationsEnabled(false)
            if note != nil {
                if self.game.currentState == Game.State.Waiting {
                    UIView.animateWithDuration(5, animations: {
                        self.noteButton.layer.borderColor = UIColor(white: 1.0, alpha: 100).CGColor
                    })
                    //frequency will never be = when the game state is in waiting
                    if note!.frequency > self.game.song!.currentNote!.frequency {
                        self.noteHigherLabel.textColor = UIColor.grayColor()
                        self.noteLowerLabel.textColor = UIColor.whiteColor()
                        //self.noteLowerLabel.hidden = true
                        self.noteHigherLabel.hidden = false
                    } else {
                        self.noteHigherLabel.textColor = UIColor.whiteColor()
                        //self.noteHigherLabel.hidden = true
                        self.noteLowerLabel.hidden = false
                        //self.noteLowerLabel.textColor = UIColor(red: 0.17647059, green: 1, blue: 1, alpha: 1)
                        self.noteLowerLabel.textColor = UIColor.grayColor()

                    }
                    
                } else if self.game.currentState == Game.State.Detecting {
                    UIView.animateWithDuration(5, animations: {
                        self.noteButton.layer.borderColor = UIColor.greenColor().CGColor
                    })
                     self.noteHigherLabel.textColor = UIColor.whiteColor()
                     self.noteLowerLabel.textColor = UIColor.whiteColor()
//                    self.noteHigherLabel.hidden = true
//                    self.noteLowerLabel.hidden = true
                    
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
                UIView.animateWithDuration(5, animations: {
                    self.noteButton.layer.borderColor = UIColor(white: 1.0, alpha: 100).CGColor
                })
                self.noteButton.setTitle("--", forState: .Normal)
                self.noteProgressView.setProgress(0.0, animated: false)
            }
            // self.currentButton.setTitle(self.game.song?.currentNote?.nameWithoutOctave, forState: .Normal)
            UIView.setAnimationsEnabled(true)
            
        })
        
    }
    
    func gameOver() {
        print("Score \(self.game.score)")
        performSegueWithIdentifier("GameOverSegue", sender: self)
        print("Hello")
    }
    
    func noteWasUpdated(note: Note?) {
        dispatch_async(dispatch_get_main_queue(), {
            
            self.score.text = "Score: \(Int(self.game.score))"
                        UIView.setAnimationsEnabled(false)
            if self.game.song != nil {
                self.game.song!.currentScore = Int(self.game.score)

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
            self.currentNoteLabel.animateToNext({ () -> () in
                self.currentNoteLabel.text = self.game.song!.currentNote?.nameWithoutOctave
            })
//            self.previousNoteLabel.animation = "fadeOut"
//            self.previousNoteLabel.duration = 1.5
//            self.previousNoteLabel.animate()
        })
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
       game.stop()
        
        if segue.identifier == "GameOverSegue" {
            
            let navController = segue.destinationViewController as? UINavigationController
            let controller = navController?.topViewController as? GameOverViewController
            if controller != nil {
                controller!.song = self.game.song!
            }
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}
