//
//  Game.swift
//  PitchPerfect
//
//  Created by blankens on 12/1/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

import Foundation
import EZAudio

protocol GameDelegate {
    func noteWasUpdated(note: Note)
}

class Game : NSObject, EZMicrophoneDelegate, EZAudioFFTDelegate {

    enum State {
        case NoteDetecting
        case NoteDetected
        case NoteCompleted
    }
    
    var delegate : GameDelegate?
    var microphone: EZMicrophone!
    var fft: EZAudioFFTRolling!
    let FFT_WINDOW_SIZE: vDSP_Length = 4096 * 2 * 2
    let pitchEstimator : PitchEstimator = PitchEstimator()
    
    var song : Song?
    var currentNote : Note?
    var score = 0
    
    init(song: Song) {
        
        super.init()
        self.song = song
        setupAudio()
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
    func fft(fft: EZAudioFFT!, updatedWithFFTData fftData: UnsafeMutablePointer<Float>, bufferSize: vDSP_Length) {
        // process results
        self.pitchEstimator.processFFT(fft as! EZAudioFFTRolling, withFFTData: fftData, ofSize: bufferSize)
        
        let fundamentalFrequency = self.pitchEstimator.fundamentalFrequency
        let noteName = EZAudioUtilities.noteNameStringForFrequency(fundamentalFrequency, includeOctave: false)
        
        let theNote = Note(frequency: Double(fundamentalFrequency))
        
        let iCents = Int(theNote.differenceInCentsToTrueNote) // Int just to get rid of decimal
        
        if delegate != nil {
            delegate!.noteWasUpdated(theNote)
        } else {
            print("No Deletage")
        }
    }
    
    func start() {
        self.song!.play()
    }
    
}
