//
//  PitchEstimator.m
//  PitchEstimation
//
//  Created by Sam Bender on 11/10/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

#import "PitchEstimator.h"
#import "SBMath.h"

@interface PitchEstimator()
{
    float previousFundamentalFrequencyBin;
}

@property (nonatomic, readwrite) float loudness;
@property (nonatomic, readwrite) float fundamentalFrequency;
@property (nonatomic, readwrite) vDSP_Length fundamentalFrequencyIndex;
@property (nonatomic, readwrite) float binSize;

@end

@implementation PitchEstimator

- (id) init
{
    self = [super init];
    if (self)
    {
        self.binInterpolationMethod = PitchEstimatorBinInterpolationMethodGaussian;
        self.windowingMethod = PitchEstimatorWindowingMethodBlackmanHarris;
    }
    return self;
}

#pragma mark - Public methods

- (void) processAudioBuffer:(float**)buffer ofSize:(UInt32)size
{
    self.loudness = [PitchEstimator loudness:buffer ofSize:size];
}

- (void) processFFT:(EZAudioFFTRolling*)fft withFFTData:(float*)fftData ofSize:(vDSP_Length)size
{
    // estimate actual frequency from bin with max freq
    // self.fundamentalFrequencyIndex = [self findFundamentalIndex:fft withBufferSize:size];
    self.fundamentalFrequencyIndex = [self findFundamental:fft atIndex:[fft maxFrequencyIndex]];
    
    if (self.binInterpolationMethod == PitchEstimatorBinInterpolationMethodGaussian)
    {
        self.fundamentalFrequency = [PitchEstimator
                                     gaussianEstimatedFrequencyOf:fft
                                     ofSize:size
                                     atIndex:self.fundamentalFrequencyIndex];
    }
    else
    {
        self.fundamentalFrequency = [fft frequencyAtIndex:self.fundamentalFrequencyIndex];
    }
    
    // set df
    self.binSize = [fft frequencyAtIndex:1] - [fft frequencyAtIndex:0];
}

#pragma mark - FFT

/**
 * More information can be found:
 * https://mgasior.web.cern.ch/mgasior/pap/FFT_resol_note.pdf
 */
+ (float) gaussianEstimatedFrequencyOf:(EZAudioFFT*)fft ofSize:(vDSP_Length)size atIndex:(vDSP_Length)index
{
    if (index == 0)
        return [fft frequencyAtIndex:0];
    
    float alpha = [fft frequencyMagnitudeAtIndex:index-1];
    float beta = [fft frequencyMagnitudeAtIndex:index];
    float gamma = [fft frequencyMagnitudeAtIndex:index+1];
    
    // shoud be between -.5 and .5
    float numerator = logf(gamma / alpha);
    float denominator = 2.0 * logf((beta * beta) / (gamma * alpha));
    float binDifference = numerator / denominator;
    
    float binSize = [fft frequencyAtIndex:1] - [fft frequencyAtIndex:0];
    float estimated = [fft frequencyAtIndex:index] + binSize * binDifference;
    
    return estimated;
}

- (int) findFundamentalIndex:(EZAudioFFTRolling*)fft withBufferSize:(vDSP_Length)bufferSize
{
    // Find the top 3 indicies with the highest magnitude
    // { highest, lower, lowest }
    float highestFrequencyMagnitudes[3] = { 0 };
    int highestFrequencyIndicies[3] = { 0 };
    for (int i = 0; i < bufferSize; i++)
    {
        float magnitude = [fft frequencyMagnitudeAtIndex:i];
        
        if (magnitude > highestFrequencyMagnitudes[2])
        {
            if (magnitude > highestFrequencyMagnitudes[1])
            {
                if (magnitude > highestFrequencyMagnitudes[0])
                {
                    highestFrequencyIndicies[0] = i;
                    highestFrequencyMagnitudes[0] = magnitude;
                }
                else
                {
                    highestFrequencyIndicies[1] = i;
                    highestFrequencyMagnitudes[1] = magnitude;
                }
            }
            else
            {
                highestFrequencyIndicies[2] = i;
                highestFrequencyMagnitudes[2] = magnitude;
            }
        }
    }
    
    
    int fundamentalIndex = highestFrequencyIndicies[0];
    if ([fft frequencyAtIndex:highestFrequencyIndicies[1]] == previousFundamentalFrequencyBin)
    {
        fundamentalIndex = highestFrequencyIndicies[1];
    }
    else if ([fft frequencyAtIndex:highestFrequencyIndicies[2]] == previousFundamentalFrequencyBin)
    {
        fundamentalIndex = highestFrequencyIndicies[2];
    }
    
    previousFundamentalFrequencyBin = [fft frequencyAtIndex:fundamentalIndex];
    
    return fundamentalIndex;
}

// e.g. octave
+ (BOOL) isFirstOvertonePresent:(EZAudioFFT*)fft atIndex:(UInt32)index
{
    float freqPower = [fft frequencyMagnitudeAtIndex:index];
    float firstOvertonePower = [fft frequencyMagnitudeAtIndex:index*2];
    float ratio = firstOvertonePower / freqPower;
    BOOL result = ratio > .1 && firstOvertonePower > .0001;
    return result;
}

+ (BOOL) isSecondOvertonePresent:(EZAudioFFT*)fft atIndex:(UInt32)index
{
    float freqPower = [fft frequencyMagnitudeAtIndex:index];
    float secondOvertonePower = [fft frequencyMagnitudeAtIndex:index*3];
    float ratio = secondOvertonePower / freqPower;
    BOOL result = ratio > .1 && secondOvertonePower > .0001;
    return result;
}

- (UInt32) findFundamental:(EZAudioFFT*)fft atIndex:(UInt32)index
{
    UInt32 foundAt = index;
    
    // I need to look more into whether this should be index over two or not
    BOOL secondOvertoneIsPresentAtIndexOverTwo = [PitchEstimator isSecondOvertonePresent:fft
                                                                                 atIndex:index/2];
    
    
    BOOL firstOvertoneIsPresentAtFifthBelow = [PitchEstimator isFirstOvertonePresent:fft
                                                                             atIndex:index*2/3];
    
    float cutoffFreq = 77.78;
    if (secondOvertoneIsPresentAtIndexOverTwo)
    {
        // cut out very low frequencies
        float freqAtLowerBin = [fft frequencyAtIndex:round(index/2)];
        if (freqAtLowerBin < cutoffFreq)
        {
            foundAt = index;
        }
        else
        {
            // recursion!
            foundAt = [self findFundamental:fft atIndex:round(index / 2)];
        }
    }
    else if (firstOvertoneIsPresentAtFifthBelow)
    {
        // cut out very low frequencies
        float freqAtLowerBin = [fft frequencyAtIndex:round(index * 2 / 3)];
        if (freqAtLowerBin < cutoffFreq)
        {
            printf("octave is present at fifth below -  cutoff\n");
            foundAt = index;
        }
        else
        {
            // recursion!
            NSLog(@"octave is present at fifth below - %f -  recursive\n", [fft frequencyAtIndex:index*2/3]);
            foundAt = [self findFundamental:fft atIndex:round(index * 2 / 3)];
        }
    }
    
    return foundAt;
}

#pragma mark - Audio

/**
 * http://stackoverflow.com/a/28734550/337934
 */
+ (float) loudness:(float**)buffer ofSize:(UInt32)bufferSize
{
    double sumSquared = 0;
    for (int i = 0 ; i < bufferSize ; i++)
    {
        sumSquared += buffer[0][i]*buffer[0][i];
    }
    double rms = sumSquared/(double)bufferSize;
    double dBvalue = 20*log10(rms);
    
    return dBvalue;
}

/**
 * Hanning window function which improves results of FFT
 */
/*
 + (void) hann:(float**)buffer length:(UInt32)length
 {
 float factor = 0;
 for (float i = 0; i < length; i++)
 {
 factor = .5 * (1 - cosf((2*M_PI*i)/(length-1)));
 buffer[0][(int)i] = buffer[0][(int)i] * factor;
 }
 }
 
 + (void) blackmanHarris:(float**)buffer length:(UInt32)length
 {
 float factor = 0;
 float a0 = 0.355768;
 float a1 = 0.487396;
 float a2 = 0.144232;
 float a3 = 0.012604;
 float lMinusOne = (float)length;
 
 for (float i = 0; i < length; i++)
 {
 factor = a0
 - a1 * cosf(2 * M_PI * i / lMinusOne)
 + a2 * cosf(4 * M_PI * i / lMinusOne)
 - a3 * cosf(6 * M_PI * i / lMinusOne);
 
 int intI = (int)i;
 buffer[0][intI] = buffer[0][intI] * factor;
 }
 }
 */

@end
