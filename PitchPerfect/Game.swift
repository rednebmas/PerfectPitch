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
    func noteWasUpdated(note: Note?)
    func pitchWasUpdated(note: Note?)
    func gameOver()
}

class Game : NSObject, EZMicrophoneDelegate, EZAudioFFTDelegate {

    enum State {
        case NotPlaying
        case Waiting
        case Detecting
        case Completed
    }
    
    enum Mode {
        case NoteByNote
        case Continous
    }
    
    let FFT_WINDOW_SIZE: vDSP_Length = 4096 * 2
    let pitchEstimator : PitchEstimator = PitchEstimator()
    
    var score: Double = 0
    var noteDetectedStart : NSDate?
    var gameStart : NSDate?
    var songDuration : NSTimeInterval = 0
    var soFarDuration: NSTimeInterval = 0
    var correctDuration : NSTimeInterval = 0
    var currentState: State = Game.State.NotPlaying
    var mode: Game.Mode = Game.Mode.Continous
    var delegate : GameDelegate?
    var microphone: EZMicrophone!
    var fft: EZAudioFFTRolling!
    var song : Song?
    var currentNote : Note?
    var previousWrongCount: Int = 0
    
    
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
        fft.shouldApplyGaussianWindow = true
        
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
        if self.currentState == Game.State.NotPlaying {
            return
        }
        
        // process results
        self.pitchEstimator.processFFT(fft as! EZAudioFFTRolling, withFFTData: fftData, ofSize: bufferSize)
        
        let fundamentalFrequency = self.pitchEstimator.fundamentalFrequency
        var note: Note? = Note(frequency: Double(fundamentalFrequency))
        
        if self.mode == Game.Mode.NoteByNote {
            if self.pitchEstimator.loudness < -80 {
                if self.currentState != Game.State.Waiting {
                    // print("Not loud enough \(self.pitchEstimator.loudness)")
                    self.currentState = Game.State.Waiting
                }
                note = nil
            }
            else if self.currentState == Game.State.Waiting {
                if note!.nameWithoutOctave == self.song!.currentNote?.nameWithoutOctave {
                    self.currentState = Game.State.Detecting
                    self.noteDetectedStart = NSDate()
                    self.previousWrongCount = 0
                    print("Started detecting")
                }
            }
            else if self.currentState == Game.State.Detecting {
                if note!.nameWithoutOctave != self.song!.currentNote?.nameWithoutOctave {
                    self.previousWrongCount++
                    print("Wrong, but continuing")
                    
                    if self.previousWrongCount > 2 {
                        print("Stopped detecting for \(note)")
                        self.currentState = Game.State.Waiting
                    }
                }
                else {
                    self.previousWrongCount = 0
                    let duration: NSTimeInterval = NSDate().timeIntervalSinceDate(self.noteDetectedStart!)
                    // print(duration)
                    // print("Completed")
                    if duration >= note?.duration {
                        note?.percentCompleted = 1
                        nextNote(false)
                    } else {
                        note?.percentCompleted = Double(duration) / (note?.duration)!
                    }
                }
            }
        }
        else if self.mode == Game.Mode.Continous {
            if note!.nameWithoutOctave == self.song!.currentNote?.nameWithoutOctave {
                let samplesPerSecond = self.microphone.audioStreamBasicDescription().mSampleRate
                self.correctDuration += 1.0 / samplesPerSecond * Double(bufferSize)
                self.score = self.correctDuration / self.songDuration * 100.0
                print("Correct for \( 1.0 / samplesPerSecond * Double(bufferSize))")
            }
        }
        
        if delegate != nil {
            delegate!.pitchWasUpdated(note)
        } else {
            print("No Deletage")
        }
    }
    
    func nextNote(skipNote: Bool) {
        if self.song!.hasNextNote() {
            self.song!.moveToNextNote()
            if self.delegate != nil {
                self.delegate!.noteWasUpdated(self.song!.currentNote)
            }
            self.song!.playCurrentNote()
            self.currentState = Game.State.Waiting
            print(self.song!.currentNote?.frequency)
            let playDuration: NSTimeInterval = NSDate().timeIntervalSinceDate(self.gameStart!)
            print(playDuration)
            if !skipNote {
                // self.score += round((self.song?.duration())! / playDuration * 100.0)
                soFarDuration += self.song!.currentNote!.duration
                self.score += round(soFarDuration / playDuration * 100)
                print("\(soFarDuration) / \(playDuration)")
            }
        }
        else {
            self.song?.stopPlaying()
            self.currentState = Game.State.NotPlaying
            
            if self.delegate != nil {
                delegate!.gameOver()
            }
        }
        

    }
    
    func start() {
        self.song!.restart()
        if self.mode == Game.Mode.NoteByNote {
            self.song!.playCurrentNote()
        } else {
            self.song!.play()
        }
        self.currentState = Game.State.Waiting
        self.soFarDuration += song!.currentNote!.duration
        self.gameStart = NSDate()
    }
    
    func stop() {
        if self.mode == Game.Mode.NoteByNote {
            self.song?.currentNote?.stop()
        } else {
            self.song?.stopPlaying()
        }
        self.currentState = Game.State.NotPlaying
    }
}
