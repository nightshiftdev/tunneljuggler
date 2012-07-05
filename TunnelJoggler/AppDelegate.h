//
//  AppDelegate.h
//  TunnelJoggler
//
//  Created by pawel on 3/7/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;
//@class CCScene;

@interface AppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
//    CCScene *scene;
}

@property (nonatomic, retain) UIWindow *window;
//@property (nonatomic, retain) CCScene *scene;

@end
