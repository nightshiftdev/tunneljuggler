//
//  ProgressHUD.h
//  TunnelJoggler
//
//  Created by pawel on 3/7/12.
//  Copyright __Pawel Kijowski__ 2012. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ProgressHUD : UIViewController
{
	UIView					*view;
	UIActivityIndicatorView *activityIndicator;
//	UILabel					*statusLabel;

//	NSString				*statusText;
//	NSTimer					*showTimer;

	CGRect					useableScreenSpace;
}

//@property (copy, readwrite, nonatomic) NSString *statusText;

@property (retain, readwrite, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicator;
//@property (retain, readwrite, nonatomic) IBOutlet UILabel *statusLabel;

+ (ProgressHUD *) sharedProgressHUD;
- (void) showProgress;
- (void) stopShowingProgress;
- (BOOL) isShowingProgress;

@end
