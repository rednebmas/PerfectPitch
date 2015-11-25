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
    
    @IBOutlet weak var debugLabel: UILabel!
    
    var microphone: EZMicrophone!
    var fft: EZAudioFFTRolling!
    let FFT_WINDOW_SIZE: vDSP_Length = 4096 * 2 * 2
    let pitchEstimator : PitchEstimator = PitchEstimator()
    
    // MARK: View controller lifecycle
    
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
        
        let sampleRate = Float(self.microphone.audioStreamBasicDescription().mSampleRate)
        fft = EZAudioFFTRolling(windowSize: FFT_WINDOW_SIZE, sampleRate: sampleRate, delegate: self)
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
    
    func fft(fft: EZAudioFFT!, updatedWithFFTData fftData: UnsafeMutablePointer<Float>, bufferSize: vDSP_Length)
    {
        // process results
        self.pitchEstimator.processFFT(fft as! EZAudioFFTRolling, withFFTData: fftData, ofSize: bufferSize)
        
        let fundamentalFrequency = self.pitchEstimator.fundamentalFrequency
        let noteName = EZAudioUtilities.noteNameStringForFrequency(fundamentalFrequency, includeOctave: false)
        
        dispatch_async(dispatch_get_main_queue(), {
            self.debugLabel.text = noteName + "\n" + fundamentalFrequency.description + "\n" + self.pitchEstimator.binSize.description
        })
    }

}
