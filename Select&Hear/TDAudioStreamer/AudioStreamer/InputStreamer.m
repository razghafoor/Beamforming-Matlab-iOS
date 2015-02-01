
//  Created by Razwan Ghafoor on 17/04/2014.
//
//  InputStreamer.m




#import "TDAudioStream.h"
#import "InputStreamer.h"
#include <math.h>



//
#pragma mark Playback callback

static OSStatus playbackCallback(void *inRefCon,
								 AudioUnitRenderActionFlags *ioActionFlags,
								 const AudioTimeStamp *inTimeStamp,
								 UInt32 inBusNumber,
								 UInt32 inNumberFrames,
								 AudioBufferList *ioData) {
    
    /**
     This is the reference to the object who owns the callback.
     */
    InputStreamer *audioProcessor = (__bridge InputStreamer*) inRefCon;
    
    // iterate over incoming stream an copy to output stream
    AudioBuffer buffer = ioData->mBuffers[0];
    
    // find minimum size
    UInt32 size = min(buffer.mDataByteSize, [audioProcessor audioBuffer].mDataByteSize);
    
    // copy buffer to audio buffer which gets played after function return
    memcpy(buffer.mData, [audioProcessor audioBuffer].mData, size);
    
    // set data size
    buffer.mDataByteSize = size;
    
    return noErr;
}

@interface InputStreamer ()  <TDAudioStreamDelegate>

@property (strong, nonatomic) TDAudioStream *audioStream1;
@property (strong, nonatomic) TDAudioStream *audioStream2;
@property (strong, nonatomic) NSThread *streamThread1;
@property (strong, nonatomic) NSThread *streamThread2;

@end

#pragma mark objective-c class

@implementation InputStreamer

@synthesize audioUnit, audioBuffer;

-(InputStreamer*)initWithInputStream:(NSInputStream *)stream1 Stream2:(NSInputStream *)stream2
{
    self = [super init];
    if (self) {
        self.audioStream1 = [[TDAudioStream alloc] initWithInputStream:stream1];
        self.audioStream1.delegate = self;
        self.audioStream2 = [[TDAudioStream alloc] initWithInputStream:stream2];
        self.audioStream2.delegate = self;
        self.streamThread1 = [[NSThread alloc] initWithTarget:self selector:@selector(run1) object:nil];
        [self.streamThread1 setName:@"AudioOutputStreamerThread1"];
        [self.streamThread1 start];
        self.streamThread2 = [[NSThread alloc] initWithTarget:self selector:@selector(run1) object:nil];
        [self.streamThread2 setName:@"AudioOutputStreamerThread2"];
        [self.streamThread2 start];
        
        [self initializeAudio];
    }
    return self;
}

- (void)run1
{
    @autoreleasepool {
        [self.audioStream1 open];
        
    }
    
    while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
    
}

- (void)run2
{
    @autoreleasepool {
        [self.audioStream2 open];
    }
    
    while ([[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) ;
    
}


-(void)initializeAudio
{
    
	
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
    
	
	// define that we want play on io on the output bus
	AudioUnitSetProperty(audioUnit,
                         kAudioOutputUnitProperty_EnableIO, // use io
                         kAudioUnitScope_Output, // scope to output
                         0, // select output bus (0)
                         &flag, // set flag
                         sizeof(flag));
	
	/*
     We need to specifie our format on which we want to work.
     We use Linear PCM cause its uncompressed and we work on raw data.
     for more informations check.
     
     We want 16 bits, 2 bytes per packet/frames at 44khz
     */
	AudioStreamBasicDescription audioFormat;
	audioFormat.mSampleRate			= SAMPLE_RATE;
	audioFormat.mFormatID			= kAudioFormatLinearPCM;
	audioFormat.mFormatFlags		= kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
	audioFormat.mFramesPerPacket	= 1;
	audioFormat.mChannelsPerFrame	= 1;
	audioFormat.mBitsPerChannel		= 16;
	audioFormat.mBytesPerPacket		= 2;
	audioFormat.mBytesPerFrame		= 2;
    
    
    
    
    // set the format on the input stream
	AudioUnitSetProperty(audioUnit,
                         kAudioUnitProperty_StreamFormat,
                         kAudioUnitScope_Input,
                         0,    //0 is output bus
                         &audioFormat,
                         sizeof(audioFormat));
	
    /**
     We need to define a callback structure which holds
     a pointer to the recordingCallback and a reference to
     the audio processor object
     */
	AURenderCallbackStruct callbackStruct;
    
    
	callbackStruct.inputProc = playbackCallback;
	callbackStruct.inputProcRefCon = (__bridge void *)(self);
    
    // set playbackCallback as callback on our renderer for the output bus
	AudioUnitSetProperty(audioUnit,
                         kAudioUnitProperty_SetRenderCallback,
                         kAudioUnitScope_Global,
                         0,
                         &callbackStruct,
                         sizeof(callbackStruct));
    
    
    
	audioBuffer.mNumberChannels = 1;
	audioBuffer.mDataByteSize = 1024 ;
	audioBuffer.mData = malloc( 1024  );
	
	// Initialize the Audio Unit and cross fingers =)
	AudioUnitInitialize(audioUnit);
    //should start here
    AudioOutputUnitStart(audioUnit);
}



#pragma mark - TDAudioStreamDelegate

- (void)audioStream:(TDAudioStream *)audioStream didRaiseEvent:(TDAudioStreamEvent)event
{
    
	
    
    float bytes[1024];
    self.Length = [audioStream readData:bytes maxLength:1024];
    
    for(int i = 0;i<1023;i++)
    {
        if (bytes[i]!=bytes[i])
        {
            bytes[i] = 0;
        }
    }
    
    
    
    
    
    memcpy(audioBuffer.mData, bytes, self.Length);
    
    
    
    
}



@end