//
//  PitchEstimator.m
//  PitchEstimation
//
//  Created by Sam Bender on 11/10/15.
//  Copyright © 2015 Sam Bender. All rights reserved.
//

#import "PitchEstimator.h"
#import "SBMath.h"


// #define MIN_FREQ 77.78
#define MIN_FREQ 90.0

typedef struct FindFundamental5Result {
    float hSum;
    vDSP_Length index;
    vDSP_Length inputIndex;
    NSInteger split;
    int name;
} FindFundamental5Result;

NSString * const StructNameField_toString[] = {
    @"Max",
    @"Lower Fifth",
    @"Lower Octave",
    @"Previous"
    
};

@interface PitchEstimator()
{
    float previousFundamentalFrequencyBin;
}

@property (nonatomic, readwrite) float signalMean;
@property (nonatomic, readwrite) float loudness;
@property (nonatomic, readwrite) float fundamentalFrequency;
@property (nonatomic, readwrite) vDSP_Length fundamentalFrequencyIndex;
@property (nonatomic, readwrite) float binSize;
@property (nonatomic, readwrite) vDSP_Length previousFundamentalIndex;

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
    self.signalMean = [SBMath meanOf:buffer[0] ofSize:size];
}

- (void) processFFT:(EZAudioFFTRolling*)fft withFFTData:(float*)fftData ofSize:(vDSP_Length)size
{
    self.previousFundamentalIndex = self.fundamentalFrequencyIndex;
    FindFundamental5Result result = [self findFundamental5:fft
                              withPreviousFundamentalIndex:self.previousFundamentalIndex
                                            withBufferSize:size];
    self.fundamentalFrequencyIndex = result.index;
    
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

#pragma mark - Fundamental finder 2

- (FindFundamental5Result) findFundamental5:(EZAudioFFT*)fft
               withPreviousFundamentalIndex:(vDSP_Length)previousFundamentalIndex
                             withBufferSize:(UInt32)bufferSize
{
    FindFundamental5Result fromCurrentMaxFreqIndexResult = [self findFundamental5:fft
                                                                          atIndex:[fft maxFrequencyIndex]
                                                                   withBufferSize:bufferSize];
    fromCurrentMaxFreqIndexResult.name = 0;
    
    if (fromCurrentMaxFreqIndexResult.index == previousFundamentalIndex)
    {
        return fromCurrentMaxFreqIndexResult;
    }
    else
    {
        FindFundamental5Result previousFundamentalIndexResult = [self findFundamental5:fft
                                                                               atIndex:previousFundamentalIndex
                                                                        withBufferSize:bufferSize];
        previousFundamentalIndexResult.name = 3;
        
        if (fromCurrentMaxFreqIndexResult.index == 82)
        {
            NSLog(@"@#");
        }
        // if current fundamental index is a harmonic
        // necessary if third harmonic is largest
        /* float currIndexFloat = fromCurrentMaxFreqIndexResult.index;
         float prevIndexFloat = previousFundamentalIndex;
         if (previousFundamentalIndex != 0)
         {
         float diffToIntegerValue = currIndexFloat / prevIndexFloat - floor(currIndexFloat / prevIndexFloat);
         if (fabsf(diffToIntegerValue) < .05 &&
         previousFundamentalIndexResult.hSum * 10 > fromCurrentMaxFreqIndexResult.hSum)
         {
         return previousFundamentalIndexResult;
         }
         } */
        
        if (fromCurrentMaxFreqIndexResult.hSum >  previousFundamentalIndexResult.hSum)
        {
            // if it is a new value, try octave below, because this algorithm has a tendency to
            // initially find higher frequencies first, then settle
            
            // make sure new index would not be illegal
            float freq = [fft frequencyAtIndex:fromCurrentMaxFreqIndexResult.index/2];
            if ([fft frequencyAtIndex:fromCurrentMaxFreqIndexResult.index/2] < MIN_FREQ)
            {
                return fromCurrentMaxFreqIndexResult;
            }
            
            FindFundamental5Result lowerOctaveFundamentalIndexResult = [self findFundamental5:fft
                                                                                      atIndex:fromCurrentMaxFreqIndexResult.index/2
                                                                               withBufferSize:bufferSize];
            lowerOctaveFundamentalIndexResult.name = 2;
            
            FindFundamental5Result lowerFifthFundamentalIndexResult = [self findFundamental5:fft
                                                                                     atIndex:fromCurrentMaxFreqIndexResult.index*2/3
                                                                              withBufferSize:bufferSize];
            
            lowerFifthFundamentalIndexResult.name = 1;
            
            
            if (lowerOctaveFundamentalIndexResult.hSum > fromCurrentMaxFreqIndexResult.hSum &&
                lowerOctaveFundamentalIndexResult.hSum > lowerFifthFundamentalIndexResult.hSum)
            {
                return lowerOctaveFundamentalIndexResult;
            }
            else if (lowerFifthFundamentalIndexResult.hSum > fromCurrentMaxFreqIndexResult.hSum &&
                     lowerFifthFundamentalIndexResult.hSum > lowerOctaveFundamentalIndexResult.hSum)
            {
                return lowerFifthFundamentalIndexResult;
            }
            else
            {
                return fromCurrentMaxFreqIndexResult;
            }
        }
        else
        {
            return previousFundamentalIndexResult;
        }
    }
}

/**
 * Don't  call this method directly
 */
- (FindFundamental5Result) findFundamental5:(EZAudioFFT*)fft
                                    atIndex:(vDSP_Length)index
                             withBufferSize:(UInt32)bufferSize
{
    vDSP_Length index2x = index * 2;
    NSInteger bestSplit = 1;
    NSInteger j = 2;
    float indexFreq = [fft frequencyAtIndex:index];
    float bestHSum = [fft frequencyMagnitudeAtIndex:index] + [fft frequencyMagnitudeAtIndex:index2x];
    float bestSplitMag = [fft frequencyMagnitudeAtIndex:index];
    float avg = [SBMath meanOf:fft.fftData ofSize:bufferSize];
    
    while (indexFreq * 1/ j > MIN_FREQ)
    {
        // if fundamental does not exist, continue
        vDSP_Length indexOfWouldBeFundamental = round((index2x-index)/j);
        float magOfWouldBeFundamental = [fft frequencyMagnitudeAtIndex:indexOfWouldBeFundamental];
        if (magOfWouldBeFundamental < bestSplitMag * .01)
        {
            // NSLog(@"base freq was not enough");
            j++;
            continue;
        }
        
        float hSum = [fft frequencyMagnitudeAtIndex:index] + [fft frequencyMagnitudeAtIndex:index2x];
        for (int k = 1; k < j; k++)
        {
            vDSP_Length harmonicKIndex = index + round((float)index * ((float)k / (float)j));
            float power = [fft frequencyMagnitudeAtIndex:harmonicKIndex];
            if (power > avg * 2)
            {
                hSum += power;
            }
        }
        
        if (hSum > bestHSum * 1.005) // better by .5 percent
        {
            bestHSum = hSum;
            bestSplit = j;
            
            vDSP_Length indexOfWouldBeFundamental = round((index2x-index)/j);
            bestSplitMag = [fft frequencyMagnitudeAtIndex:indexOfWouldBeFundamental];
        }
        
        j++;
    }
    
    // add next harmonics if they are within reasonable range of our max value so the octave checker above favors
    // a best split of 1
    if (bestSplit == 1 && [fft frequencyMagnitudeAtIndex:index] > avg * 10.0) {
        float thirdHarmonicMagnitude = [fft frequencyMagnitudeAtIndex:index*3];
        float fourthHarmonicMagnitude = [fft frequencyMagnitudeAtIndex:index*4];
        if (thirdHarmonicMagnitude > [fft frequencyMagnitudeAtIndex:index] * .25) {
            bestHSum += thirdHarmonicMagnitude;
        }
        if (fourthHarmonicMagnitude > [fft frequencyMagnitudeAtIndex:index] * .25) {
            bestHSum += fourthHarmonicMagnitude;
        }
    }
    
    FindFundamental5Result result;
    result.index = round((index2x-index)/bestSplit);
    result.hSum = bestHSum;
    result.inputIndex = index;
    result.split = bestSplit;
    
    return result;
}
#pragma mark - Other fundamental finders

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
- (BOOL) isFirstOvertonePresent:(EZAudioFFT*)fft atIndex:(UInt32)index
{
    float freqPower = [fft frequencyMagnitudeAtIndex:index];
    float firstOvertonePower = [fft frequencyMagnitudeAtIndex:index*2];
    float ratio = firstOvertonePower / freqPower;
    //    BOOL result = ratio > .05 && freqPower > .00020 * . 1;
    BOOL result = firstOvertonePower > self.signalMean;
    // NSLog(@"octave ratio: %f, power: %.10f, result: %@", ratio, firstOvertonePower, result ? @"t" : @"f");
    return result;
}

- (BOOL) isSecondOvertonePresent:(EZAudioFFT*)fft atIndex:(UInt32)index
{
    float freqPower = [fft frequencyMagnitudeAtIndex:index];
    float secondOvertonePower = [fft frequencyMagnitudeAtIndex:index*3];
    float ratio = secondOvertonePower / freqPower;
    //    BOOL result = ratio > .01 && secondOvertonePower > 0.000021;
    //    BOOL result = ratio > .05 && freqPower > .00010 * .1;
    BOOL result = secondOvertonePower > self.signalMean || freqPower > .0001;
    // NSLog(@"second overtone ratio: %f, power: %f, result: %@", ratio, secondOvertonePower, result ? @"t" : @"f");
    return result;
}

- (UInt32) findFundamental:(EZAudioFFT*)fft atIndex:(UInt32)index
{
    UInt32 foundAt = index;
    
    // self.oneIfHarmonicOtherwiseZero[foundAt] = 1;
    
    // I need to look more into whether this should be index over two or not
    // NSLog(@"%f", [fft maxFrequencyMagnitude]);
    float freq = [fft frequencyAtIndex:index];
    float lowerOctaveFreq = [fft frequencyAtIndex:index];
    BOOL secondOvertoneIsPresentAtIndexOverTwo = [self isSecondOvertonePresent:fft
                                                                       atIndex:index/2];
    float secondOvertonePower = [fft frequencyMagnitudeAtIndex:(index/2)*3];
    
    BOOL firstOvertoneIsPresentAtFifthBelow = [self isFirstOvertonePresent:fft
                                                                   atIndex:index*2/3];
    float firstOvertonePower = [fft frequencyMagnitudeAtIndex:(index*4/3)];
    
    if ((secondOvertoneIsPresentAtIndexOverTwo && secondOvertonePower > firstOvertonePower) ||
        [fft frequencyMagnitudeAtIndex:index/2] / [fft frequencyMagnitudeAtIndex:index] > .75)
    {
        // cut out very low frequencies
        float freqAtLowerBin = [fft frequencyAtIndex:round(index/2)];
        if (freqAtLowerBin < MIN_FREQ)
        {
            foundAt = index;
        }
        else
        {
            // recursion!
            foundAt = [self findFundamental:fft atIndex:round(index / 2)];
        }
    }
    else if (firstOvertoneIsPresentAtFifthBelow && firstOvertonePower > secondOvertonePower)
    {
        // cut out very low frequencies
        float freqAtLowerBin = [fft frequencyAtIndex:round(index / 2)];
        if (freqAtLowerBin < MIN_FREQ)
        {
            // printf("octave is present at fifth below -  cutoff\n");
            foundAt = index;
        }
        else
        {
            // recursion!
            // NSLog(@"octave is present at fifth below - %f -  recursive\n", [fft frequencyAtIndex:index*2/3]);
            foundAt = [self findFundamental:fft atIndex:round(index * 2 / 3)];
        }
    }
    
    if (foundAt == 23) {
        NSLog(@"second overtone: %.9f", [fft frequencyMagnitudeAtIndex:foundAt * 3]);
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
