//
//  AppDelegate.h
//  TunnelJoggler
//
//  Created by pawel on 3/7/12.
//  Copyright __Pawel Kijowski__ 2012. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>
#import "GameCenterManager.h"
#import "GameController.h"

@class RootViewController;
@class CCScene;

@interface AppDelegate : NSObject <UIApplicationDelegate, GameControllerDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
    GameCenterManager *gameCenterManager;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) GameCenterManager *gameCenterManager;

- (BOOL) shouldAdjustViewRotation;

@end
