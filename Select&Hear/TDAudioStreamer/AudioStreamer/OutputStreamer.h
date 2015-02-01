//
//  OutputStreamer.h
//  TDAudioStreamer
//
//  Created by Razwan Ghafoor on 17/04/2014.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

// return max value for given values
#define max(a, b) (((a) > (b)) ? (a) : (b))
// return min value for given values
#define min(a, b) (((a) < (b)) ? (a) : (b))

// our default sample rate
#define SAMPLE_RATE 4410.00
//say I changed

@interface OutputStreamer : NSObject
{
    // Audio unit
    AudioComponentInstance audioUnit;
    
    // Audio buffers
	AudioBuffer audioBuffer;
    
}

@property (readonly) AudioBuffer audioBuffer;
@property (readonly) AudioComponentInstance audioUnit;



-(OutputStreamer*)initWithOutputStream:(NSOutputStream *)stream Delay:(float)del;

-(void)initializeAudio;
-(void)processBuffer: (AudioBufferList*) audioBufferList;

- (void)run;


@end
