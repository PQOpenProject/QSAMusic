#import <UIKit/UIKit.h>

#import "AEAudioBufferManager.h"
#import "AEAudioController+Audiobus.h"
#import "AEAudioController+AudiobusStub.h"
#import "AEAudioController.h"
#import "AEAudioFileLoaderOperation.h"
#import "AEAudioFilePlayer.h"
#import "AEAudioFileWriter.h"
#import "AEAudioUnitChannel.h"
#import "AEAudioUnitFilter.h"
#import "AEBlockAudioReceiver.h"
#import "AEBlockChannel.h"
#import "AEBlockFilter.h"
#import "AEBlockScheduler.h"
#import "AEFloatConverter.h"
#import "AEMemoryBufferPlayer.h"
#import "AEMessageQueue.h"
#import "AEUtilities.h"
#import "TPCircularBuffer+AudioBufferList.h"
#import "TPCircularBuffer.h"
#import "TheAmazingAudioEngine.h"
#import "AEExpanderFilter.h"
#import "AELimiter.h"
#import "AELimiterFilter.h"
#import "AEMixerBuffer.h"
#import "AEPlaythroughChannel.h"
#import "AERecorder.h"
#import "AESequencerBeat.h"
#import "AESequencerChannel.h"
#import "AESequencerChannelSequence.h"
#import "AEBandpassFilter.h"
#import "AEDelayFilter.h"
#import "AEDistortionFilter.h"
#import "AEDynamicsProcessorFilter.h"
#import "AEHighPassFilter.h"
#import "AEHighShelfFilter.h"
#import "AELowPassFilter.h"
#import "AELowShelfFilter.h"
#import "AENewTimePitchFilter.h"
#import "AEParametricEqFilter.h"
#import "AEPeakLimiterFilter.h"
#import "AEReverbFilter.h"
#import "AEVarispeedFilter.h"

FOUNDATION_EXPORT double TheAmazingAudioEngineVersionNumber;
FOUNDATION_EXPORT const unsigned char TheAmazingAudioEngineVersionString[];

