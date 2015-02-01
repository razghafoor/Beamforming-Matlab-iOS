//
//  InputStreamer.h
//  TDAudioStreamer
//
//  Created by Razwan Ghafoor on 17/04/2014.


#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

// return max value for given values
#define max(a, b) (((a) > (b)) ? (a) : (b))
// return min value for given values
#define min(a, b) (((a) < (b)) ? (a) : (b))

// our default sample rate
#define SAMPLE_RATE 4410.00

@interface InputStreamer : NSObject
{
    // Audio unit
    AudioComponentInstance audioUnit;
    
    // Audio buffers
	AudioBuffer audioBuffer;
    
    
    
}

@property (readonly) AudioBuffer audioBuffer;
@property (readonly) AudioComponentInstance audioUnit;
@property (nonatomic) UInt32 Length;


-(InputStreamer*)initWithInputStream:(NSInputStream *)stream1 Stream2:(NSInputStream *)stream2;

-(void)initializeAudio;

- (void)run1;
- (void)run2;


@end
