//
//  GuestViewController.m
//  TDAudioStreamer


#import "TDMultipeerGuestViewController.h"
#import "TDSession.h"
#import "OutputStreamer.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

NSString *name;

@interface TDMultipeerGuestViewController ()

@property (strong, nonatomic) TDSession *session;
@property (strong, nonatomic) OutputStreamer *outputStreamer;

@end

@implementation TDMultipeerGuestViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
}




- (IBAction)numberChange:(UISegmentedControl *)sender {
    
    
    name = [NSString stringWithFormat:@"%ld", (long)sender.selectedSegmentIndex];
    
                      
    self.session = [[TDSession alloc] initWithPeerDisplayName:name];
    [self.session startAdvertisingForServiceType:@"dance-party" discoveryInfo:nil];
    
    
}

- (IBAction)start:(UIButton *)sender {
    
    NSArray *peers = [self.session connectedPeers];

    
    float a = [name floatValue];
    
    for (MCPeerID *peer in peers) {
        if ([peer.displayName isEqualToString:@"Host"]){
            if (!self.outputStreamer)
                //cos(0) =1 l = 0.8 cm
                self.outputStreamer = [[OutputStreamer alloc] initWithOutputStream:[self.session outputStreamForPeer:peer] Delay:((0.008*a)/343)];
        }
    }
}


@end
