//
//  GameModeViewController.swift
//  PerfectPitch
//
//  Created by Ian Palmgren on 12/14/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import UIKit

class GameModeViewController: UIViewController {
    
    lazy var game: Game = Game(song: Song(title: ""))


    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "noteGameViewSegue" {
            
            if let controller = segue.destinationViewController as? GameViewController {
                controller.game.song = game.song
                controller.game.mode = Game.Mode.NoteByNote
            }
        }
        
        if segue.identifier == "contGameViewSegue" {
            
            if let controller = segue.destinationViewController as? GameViewController {
                controller.game.song = game.song
                controller.game.mode = Game.Mode.Continous
                controller.noteByNote = false
            }
        }
    }

}
