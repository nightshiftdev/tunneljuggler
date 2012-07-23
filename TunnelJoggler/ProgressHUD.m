//
//  ProgressHUD.m
//  TunnelJoggler
//
//  Created by pawel on 3/7/12.
//  Copyright __Pawel Kijowski__ 2012. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>
#import "ProgressHUD.h"

static CGFloat kWindowMargin = 8.0;

@interface ProgressHUD ()
- (void) viewDidLoad;
- (void) recalculateSize;
- (void) hideStatusView;
//- (void) showStatusAfterDelay;
- (void) showStatusView;
//- (void) hideStatusViewIfNeeded;

//- (void) startListeningToActivityTracker: (SLActivityTracker *) activityTracker;
//- (void) stopListeningToActivityTracker: (SLActivityTracker *) activityTracker;
@end

@implementation ProgressHUD

@synthesize view;
@synthesize activityIndicator;
//@synthesize activityTrackers;

+ (ProgressHUD *) sharedProgressHUD
{
	static ProgressHUD *gSharedProgressHUD = nil;

	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		gSharedProgressHUD = [[ProgressHUD alloc] init];
		if([[NSBundle mainBundle] loadNibNamed: @"ProgressHUD" owner: gSharedProgressHUD options: nil])
		{
			[gSharedProgressHUD viewDidLoad];
		}
	});

	return gSharedProgressHUD;
}

- (void) dealloc
{
    [super dealloc];
    self.activityIndicator = nil;
//	self.statusText = nil;
//	self.statusLabel = nil;
}

- (void) showProgress
{
//    [self hideStatusViewIfNeeded];
    [self showStatusView];
}

- (void) stopShowingProgress
{
    [self hideStatusView];
}

//- (void) showProgressForActivityTracker: (SLActivityTracker *) activityTracker
//{
//	NSAssert(nil != activityTracker, @"");
//
//	if(!self.activityTrackers)
//	{
//		self.activityTrackers = [NSArray array];
//	}
//
//	if(![self.activityTrackers containsObject: activityTracker])
//	{
//		self.activityTrackers = [self.activityTrackers arrayByAddingObject: activityTracker];
//
//		[self startListeningToActivityTracker: activityTracker];
//	}
//}

//- (void) stopShowingProgressForActivityTracker: (SLActivityTracker *) activityTracker
//{
//	NSAssert(nil != activityTracker, @"");
//
//	[self stopListeningToActivityTracker: activityTracker];
//
//	NSMutableArray *newTrackers = [self.activityTrackers mutableCopy];
//	[newTrackers removeObjectIdenticalTo: activityTracker];
//
//	self.activityTrackers = newTrackers;
//}

//- (void) startListeningToActivityTracker: (SLActivityTracker *) activityTracker
//{
//	NSAssert(nil != activityTracker, @"");
//
//	[[NSNotificationCenter defaultCenter] addObserver: self
//											 selector: @selector(handleActivityBegan:)
//												 name: SLActivityTrackerActivityBegan
//											   object: activityTracker];
//
//	[[NSNotificationCenter defaultCenter] addObserver: self
//											 selector: @selector(handleActivityEnded:)
//												 name: SLActivityTrackerActivityEnded
//											   object: activityTracker];
//}

//- (void) stopListeningToActivityTracker: (SLActivityTracker *) activityTracker
//{
//	NSAssert(nil != activityTracker, @"");
//	[[NSNotificationCenter defaultCenter] removeObserver: self
//													name: nil
//												  object: activityTracker];
//}

//- (void) handleActivityBegan: (NSNotification *) notification
//{
//	[self updateStatusText];
//	[self showStatusAfterDelay];
//}

//- (void) handleActivityEnded: (NSNotification *) notification
//{
//	[self updateStatusText];
//	[self hideStatusViewIfNeeded];
//}

//- (UILabel *) statusLabel
//{
//	return statusLabel;
//}
//
//- (void) setStatusLabel: (UILabel *) newLabel
//{
//	if(newLabel != statusLabel)
//	{
//		statusLabel = newLabel;
//	}
//}

- (void) viewDidLoad
{
    [[[UIApplication sharedApplication] delegate].window addSubview:self.view];
	[self recalculateSize];
	[self hideStatusView];

	self.view.layer.cornerRadius = 8.0;
    self.view.layer.masksToBounds = NO;
    self.view.layer.shadowOffset = CGSizeMake(0.0, 9.0);
    self.view.layer.shadowRadius = 8.0;
    self.view.layer.shadowOpacity = 0.5;
    


	useableScreenSpace = [[UIScreen mainScreen] applicationFrame];

	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(keyboardWillShow:)
												 name: UIKeyboardWillShowNotification
											   object: nil];

	[[NSNotificationCenter defaultCenter] addObserver: self
											 selector: @selector(keyboardWillHide:)
												 name: UIKeyboardWillHideNotification
											   object: nil];

//	[[NSNotificationCenter defaultCenter] addObserver: self
//											 selector: @selector(deviceOrientationChanged:)
//												 name: UIDeviceOrientationDidChangeNotification
//											   object: nil];
}

- (void) viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) keyboardWillShow: (NSNotification *) notification
{
	CGRect keyboardFrame = [[[notification userInfo] valueForKey: UIKeyboardFrameEndUserInfoKey] CGRectValue];

	useableScreenSpace = [[UIScreen mainScreen] applicationFrame];
	useableScreenSpace.size.height = CGRectGetMinY(keyboardFrame) - CGRectGetMinY(useableScreenSpace);

	self.view.center = CGPointMake(CGRectGetMidX(useableScreenSpace), CGRectGetMidY(useableScreenSpace));
}

- (void) keyboardWillHide: (NSNotification *) notification
{
	useableScreenSpace = [[UIScreen mainScreen] applicationFrame];
}

//- (void) showStatusAfterDelay
//{
//	// If the view is currently hidden, begin a timer that will show it.
//	if(!showTimer)
//	{
//		showTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5
//													 target: self
//												   selector: @selector(showTimerFired:)
//												   userInfo: nil
//													repeats: NO];
//	}
//}
//
//- (void) hideStatusViewIfNeeded
//{
//    if(showTimer)
//    {
//        [showTimer invalidate];
//        showTimer = nil;
//    }
//    
//    [self hideStatusView];
//}

- (void) showStatusView
{
	[self recalculateSize];

	self.view.center = CGPointMake(CGRectGetMidX(useableScreenSpace), CGRectGetMidY(useableScreenSpace));
	self.view.alpha = 0;
	self.view.hidden = NO;

    [[[UIApplication sharedApplication] delegate].window bringSubviewToFront: self.view];

	[UIView beginAnimations: @"ShowingStatusView" context: nil];
	self.view.alpha = 1.0;
	[UIView commitAnimations];

	[activityIndicator startAnimating];
}

- (void) hideStatusView
{
	[activityIndicator stopAnimating];
	self.view.hidden = YES;
}

- (BOOL) isShowingProgress
{
    return !self.view.isHidden;
}

//- (BOOL) hasActivitesToShow
//{
//	__block BOOL hasActivities = NO;
//
//	[self.activityTrackers enumerateObjectsUsingBlock:^(SLActivityTracker *activityTracker, NSUInteger idx, BOOL *stop) {
//		hasActivities = [activityTracker.currentActivities count] > 0;
//		if(stop)
//		{
//			*stop = hasActivities;
//		}
//	}];
//
//	return hasActivities;
//}

//- (void) updateStatusText
//{
//	for(SLActivityTracker *activityTracker in self.activityTrackers)
//	{
//		if(activityTracker.currentActivities && [activityTracker.currentActivities count] > 0)
//		{
//			NSString *contextToShow = [[activityTracker.currentActivities allKeys] lastObject];
//			self.statusText = [activityTracker.currentActivities objectForKey: contextToShow];
//		}
//	}
//}

//- (void) showTimerFired: (NSTimer *) timerThatFired
//{
//	check(timerThatFired == showTimer);
//
//	[self showStatusView];
//
//	[showTimer invalidate];
//	showTimer = nil;
//}

//- (NSString *) statusText
//{
//	return statusText;
//}
//
//- (void) setStatusText: (NSString *) newText
//{
//	if(newText != statusText)
//	{
//
//		statusText = [newText copy];
//		[self recalculateSize];
//	}
//
//	statusLabel.text = self.statusText;
//}

- (void) recalculateSize
{
//	CGSize textSize = [self.statusText sizeWithFont: statusLabel.font
//								  constrainedToSize: CGSizeMake(300, 300)
//									  lineBreakMode: statusLabel.lineBreakMode];
//
//	CGRect newLabelFrame = statusLabel.frame;
//	newLabelFrame.size.width = textSize.width;
//	statusLabel.frame = newLabelFrame;

	CGFloat activityWidth = (activityIndicator.frame.size.width) + 2 * kWindowMargin;
    CGFloat activityHeight = (activityIndicator.frame.size.height) + 2 * kWindowMargin;
//	CGFloat statusWidth = (statusLabel.frame.size.width) + 2 * kWindowMargin;

	CGRect newBounds = self.view.bounds;
	newBounds.size.width = activityWidth; //fmax(activityWidth, statusWidth);
	//newBounds.size.height = CGRectGetMaxY(statusLabel.frame) - CGRectGetMinY(activityIndicator.frame) + 2 * kWindowMargin;
    newBounds.size.height = activityHeight; //CGRectGetMinY(activityIndicator.frame) + 2 * kWindowMargin;
	self.view.bounds = newBounds;

	activityIndicator.center = CGPointMake(CGRectGetMidX(self.view.bounds), kWindowMargin + CGRectGetWidth(activityIndicator.frame) / 2.0);
//	statusLabel.center = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMaxY(self.view.bounds) - kWindowMargin - CGRectGetHeight(statusLabel.frame) / 2.0);

	self.view.center = CGPointMake(CGRectGetMidX(useableScreenSpace), CGRectGetMidY(useableScreenSpace));
}

- (void) deviceOrientationChanged: (NSNotification *) notification
{
	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];

	[UIView beginAnimations: @"RotateProgressHUD" context: nil];
	switch(deviceOrientation)
	{
		case UIDeviceOrientationPortrait :
			self.view.transform = CGAffineTransformIdentity;
			break;

		case UIDeviceOrientationPortraitUpsideDown :
			self.view.transform = CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI);
			break;

		case UIDeviceOrientationLandscapeLeft :
			self.view.transform = CGAffineTransformMakeRotation(M_PI / 2);
			break;

		case UIDeviceOrientationLandscapeRight :
			self.view.transform = CGAffineTransformMakeRotation(-M_PI / 2);
			break;

		default:
			self.view.transform = CGAffineTransformIdentity;
			break;
	}
	[UIView commitAnimations];
}

@end
