//
//  TDMultipeerHostViewController.m
//  TDAudioStreamer


#import <MultipeerConnectivity/MultipeerConnectivity.h>

#import "TDMultipeerHostViewController.h"

#import "TDSession.h"
#import "InputStreamer.h"

float angleChange;

@interface TDMultipeerHostViewController () <TDSessionDelegate>



@property (strong, nonatomic) TDSession *session;
@property (strong, nonatomic) InputStreamer *inputStream;
@property (strong, nonatomic) NSInputStream *stream1;

@end

@implementation TDMultipeerHostViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
	self.session = [[TDSession alloc] initWithPeerDisplayName:@"Host"];
    angleChange = 0;
    self.session.delegate = self;
    //self.angleLabel.text = @"0 radians";
}




#pragma mark - View Actions

- (IBAction)invite:(id)sender
{
    [self presentViewController:[self.session browserViewControllerForSeriviceType:@"dance-party"] animated:YES completion:nil];
    
    
}



- (IBAction)angleSlider:(id)sender {
    UISlider *slider = (UISlider *)sender;
    float angle = 10*slider.value*M_2_PI;
    NSString *angleValue;
    
    angleValue = [NSString stringWithFormat:@"%f radians",angle];
    self.angleLabel.text = angleValue;
    
    
    
    self.compassView.transform = CGAffineTransformRotate(self.compassView.transform, (angle-angleChange));
    angleChange = angle;
    
                                                         
}




- (void)session:(TDSession *)session didReceiveAudioStream:(NSInputStream *)stream
{
    
    
    if ((!self.inputStream)&&(self.stream1)) {
        self.inputStream = [[InputStreamer alloc] initWithInputStream:self.stream1 Stream2:stream];
    }
    if(!self.stream1)
    {
       self.stream1 = stream;
        
    }
}



@end
