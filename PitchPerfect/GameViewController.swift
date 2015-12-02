//
//  GameViewController.swift
//  PitchPerfect
//
//  Created by Sam Bender on 11/23/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import UIKit
import EZAudio

class GameViewController: UIViewController, EZMicrophoneDelegate, EZAudioFFTDelegate {
    
    // MARK: Properties 
    
    @IBOutlet weak var noteButton: UIButton!
    @IBOutlet weak var nextNoteLabel: UILabel!
    @IBOutlet weak var currentNoteLabel: UILabel!
    @IBOutlet weak var previousNoteLabel: UILabel!
    
    var song : Song = Song()
    var microphone: EZMicrophone!
    var fft: EZAudioFFTRolling!
    let FFT_WINDOW_SIZE: vDSP_Length = 4096 * 2 * 2
    let pitchEstimator : PitchEstimator = PitchEstimator()
    
    // MARK: View controller lifecycle
    
    struct defaultKeys {
        static let localStorageKey = "LocalStorageKey"
    }
    
    var songArray : [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupAudio()
        self.song.play()
        
        noteButton.layer.borderWidth = 2
        noteButton.layer.borderColor = UIColor(white: 1.0, alpha: 100).CGColor
        
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
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.song.stopPlaying()
    }
    
    // MARK: Audio
    
    /**
     * Based on code from https://github.com/syedhali/EZAudio-Swift/blob/master/EZAudio-Swift/ViewController.swift
     */
    func setupAudio() {
        //
        // Setup the AVAudioSession. EZMicrophone will not work properly on iOS
        // if you don't do this!
        //
        let session : AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try session.setActive(true)
        } catch _ {
            print("Error setting up audio session.")
        }
        
        microphone = EZMicrophone(delegate: self)
        
        let sampleRate = Float(self.microphone.audioStreamBasicDescription().mSampleRate)
        fft = EZAudioFFTRolling(windowSize: FFT_WINDOW_SIZE, sampleRate: sampleRate, delegate: self)
        
        microphone.startFetchingAudio()
    }
    
    /**
     * Microphone delegate
     */
    func microphone(microphone: EZMicrophone!, hasAudioReceived buffer: UnsafeMutablePointer<UnsafeMutablePointer<Float>>, withBufferSize bufferSize: UInt32, withNumberOfChannels numberOfChannels: UInt32)
    {
        // applies window function and determines volume
        self.pitchEstimator.processAudioBuffer(buffer, ofSize: bufferSize)
        
        // calculate fft
        self.fft.computeFFTWithBuffer(buffer[0], withBufferSize: bufferSize)
    }
    
    /**
     * EZAudioFFT delegate
     */
    func fft(fft: EZAudioFFT!, updatedWithFFTData fftData: UnsafeMutablePointer<Float>, bufferSize: vDSP_Length)
    {
        // process results
        self.pitchEstimator.processFFT(fft as! EZAudioFFTRolling, withFFTData: fftData, ofSize: bufferSize)
        
        let fundamentalFrequency = self.pitchEstimator.fundamentalFrequency
        let noteName = EZAudioUtilities.noteNameStringForFrequency(fundamentalFrequency, includeOctave: false)
        
        let theNote = Note(frequency: Double(fundamentalFrequency))
        
        let iCents = Int(theNote.differenceInCentsToTrueNote) // Int just to get rid of decimal
        
        dispatch_async(dispatch_get_main_queue(), {
//            self.debugLabel.text = noteName + "\n" + fundamentalFrequency.description + "\n" + self.pitchEstimator.binSize.description + "\nCents: " + iCents.description
            
            self.noteButton.setTitle(noteName, forState: .Normal)
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
