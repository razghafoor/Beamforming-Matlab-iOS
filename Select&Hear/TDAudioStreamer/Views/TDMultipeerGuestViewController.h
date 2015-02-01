//
//  GuestViewController.h
//


#import <UIKit/UIKit.h>

@interface TDMultipeerGuestViewController : UIViewController

@property (strong, nonatomic) IBOutlet UISegmentedControl *number;

- (IBAction)numberChange:(UISegmentedControl *)sender;


@end
