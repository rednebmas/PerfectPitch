//
//  GameViewController.swift
//  PitchPerfect
//
//  Created by Sam Bender on 11/23/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import UIKit
import EZAudio

class GameViewController: UIViewController, EZMicrophoneDelegate {
    
    var microphone: EZMicrophone!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAudio()
    }
    
    // MARK: Audio
    
    /**
     * Based on code from https://github.com/syedhali/EZAudio-Swift/blob/master/EZAudio-Swift/ViewController.swift
     */
    func setupAudio() {
        microphone = EZMicrophone(delegate: self, startsImmediately: true);
    }
    
    /**
     * Microphone delegate
     */
    func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32)
    {
        print("Recieved microphone input")
    }

}
