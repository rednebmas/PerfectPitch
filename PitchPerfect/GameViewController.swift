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
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var currentButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    
    var song : Song = Song()
    lazy var game: Game = Game(song: Song())
    // MARK: View controller lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        self.song.play()
        self.game = Game(song: song)
        self.game.delegate = self
        
        noteButton.layer.borderWidth = 2
        noteButton.layer.borderColor = UIColor(white: 1.0, alpha: 100).CGColor
        
        previousButton.setTitle("pNote", forState: .Normal)
        currentButton.setTitle("cNote", forState: .Normal)
        nextButton.setTitle("nNote", forState: .Normal)
        game.start()
        
        //
        // Simple example of how to play just one note
        //
        
        /*
        
        let note = Note(noteName: "A4", duration: 1.0)
        note.play() // plays until stop() is called
        // or
        note.playForDuration()
        
        */
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.game.song!.stopPlaying() //ToDo: create Game stop Playing Method
    }
    
    
    //
    func noteWasUpdated(note: Note) {
        dispatch_async(dispatch_get_main_queue(), {
            self.noteButton.setTitle(note.fullNameWithoutOctave, forState: .Normal)
        })
    }

}
