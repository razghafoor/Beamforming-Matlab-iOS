//
//  OutputStreamer.m
//  TDAudioStreamer
//
//  Created by Razwan Ghafoor on 17/04/2014.
//

#import "OutputStreamer.h"
#import "TDAudioStream.h"
#include <math.h>

float delay;

#pragma mark Recording callback

static OSStatus recordingCallback(void *inRefCon,
                                  AudioUnitRenderActionFlags *ioActionFlags,
                                  const AudioTimeStamp *inTimeStamp,
                                  UInt32 inBusNumber,
                                  UInt32 inNumberFrames,
                                  AudioBufferList *ioData) {
	
	// the data gets rendered here
    AudioBuffer buffer;
    
    
    /**
     This is the reference to the object who owns the callback.
     */
    OutputStreamer *audioProcessor = (__bridge OutputStreamer*) inRefCon;
    
    /**
     on this point we define the number of channels, which is mono
     for the iphone. the number of frames is usally 512 or 1024.
     */
    buffer.mDataByteSize = inNumberFrames *2; // sample size
    buffer.mNumberChannels = 1; // one channel
	buffer.mData = malloc( inNumberFrames *2 ); // buffer size
	
    // we put our buffer into a bufferlist array for rendering
	AudioBufferList bufferList;
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0] = buffer;
    
    // render input
    AudioUnitRender([audioProcessor audioUnit], ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &bufferList);
    
	// process the bufferlist in the audio processor
    [audioProcessor processBuffer:&bufferList];
	
    // clean up the buffer
	free(bufferList.mBuffers[0].mData);
	
    return noErr;
}


@interface OutputStreamer () <TDAudioStreamDelegate>

@property (strong, nonatomic) TDAudioStream *audioStream;
@property (strong, nonatomic) NSThread *streamThread;

@end

#pragma mark objective-c class


@implementation OutputStreamer
@synthesize audioUnit, audioBuffer;


-(OutputStreamer*)initWithOutputStream:(NSOutputStream *)stream Delay:(float)del
{
    self = [super init];
    if (self) {
        delay = del;
        self.audioStream = [[TDAudioStream alloc] initWithOutputStream:stream];
        self.audioStream.delegate = self;
        self.streamThread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        [self.streamThread setName:@"TDAudioOutputStreamerThread"];
        [self.streamThread start];
        [self initializeAudio];
    }
    return self;
}

- (void)run
{
    @autoreleasepool {
        [self.audioStream open];
    }
    while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
    
    
}

-(void)initializeAudio
{
    OSStatus status;
	
	// We define the audio component
	AudioComponentDescription desc;
	desc.componentType = kAudioUnitType_Output; // we want to ouput
	desc.componentSubType = kAudioUnitSubType_RemoteIO; // we want in and output
	desc.componentFlags = 0; // must be zero
	desc.componentFlagsMask = 0; // must be zero
	desc.componentManufacturer = kAudioUnitManufacturer_Apple; // select provider
	
	// find the AU component by description
	AudioComponent inputComponent = AudioComponentFindNext(NULL, &desc);
	
	// create audio unit by component
	AudioComponentInstanceNew(inputComponent, &audioUnit);
    
	
    // define that we want record io on the input bus
    UInt32 flag = 1;
    AudioUnitSetProperty(audioUnit,
                         kAudioOutputUnitProperty_EnableIO, // use io
                         kAudioUnitScope_Input, // scope to input
                         1, // select input bus (1)
                         &flag, // set flag
                         sizeof(flag));
	
    
	
	
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate			= SAMPLE_RATE;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 1;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 2;
	audioFormat.mBytesPerFrame		= 2;
    
    
    
	// set the format on the output stream
	AudioUnitSetProperty(audioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Output,
                         1,
                         &audioFormat,
                         sizeof(audioFormat));
    
    /**
     We need to define a callback structure which holds
     a pointer to the recordingCallback and a reference to
     the audio processor object
     */
	AURenderCallbackStruct callbackStruct;
    
    // set recording callback
	callbackStruct.inputProc = recordingCallback; // recordingCallback pointer
	callbackStruct.inputProcRefCon = (__bridge void *)(self);
    
    // set input callback to recording callback on the input bus
	AudioUnitSetProperty(audioUnit,
                         kAudioOutputUnitProperty_SetInputCallback,
                         kAudioUnitScope_Global,
                         1,    //input bus is 1
                         &callbackStruct,
                         sizeof(callbackStruct));
	
    /*
     We do the same on the output stream to hear what is coming
     from the input stream
     */
	
	flag = 0;
    
    /*
     we need to tell the audio unit to allocate the render buffer,
     that we can directly write into it.
     */
	status = AudioUnitSetProperty(audioUnit,
								  kAudioUnitProperty_ShouldAllocateBuffer,
								  kAudioUnitScope_Output,
								  1,    //input bus is 1
								  &flag,
								  sizeof(flag));
	
    
    /*
     we set the number of channels to mono and allocate our block size to
     1024 bytes.
     */
	audioBuffer.mNumberChannels = 1;
    //2
	audioBuffer.mDataByteSize = 1024 ;
    //2
	audioBuffer.mData = malloc( 1024 );
	
	// Initialize the Audio Unit
	AudioUnitInitialize(audioUnit);
    //should start here
    AudioOutputUnitStart(audioUnit);
}



#pragma mark processing

-(void)processBuffer: (AudioBufferList*) audioBufferList
{
    
    // EXAMPLE OF HOW TO IMPLEMENT DELAY:  cos(60) = 1/2 length = 0.5 cm C = 343 m/s
    float delay = 0.0025/343;
    [NSThread sleepForTimeInterval:delay];
    
    [self.audioStream writeData:audioBufferList->mBuffers[0].mData maxLength:audioBufferList->mBuffers[0].mDataByteSize];
    
    
    
}

- (void)audioStream:(TDAudioStream *)audioStream didRaiseEvent:(TDAudioStreamEvent)event
{
}

@end
