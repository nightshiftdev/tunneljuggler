//
//  SplashScene.mm
//  TunnelJuggler
//
//  Created by pawel on 4/21/11.
//  Copyright 2011 __etcApps__. All rights reserved.
//

#import "SplashScene.h"
#import "BackgroundUtils.h"
#import "SoundMenuItem.h"
#import "SimpleAudioEngine.h"

@interface SplashScene()
@end


@implementation SplashScene

+(id) scene {
	CCScene *scene = [CCScene node];
	id child = [SplashScene node];
	
	[scene addChild:child];
	return scene;
}

-(id) init {
	if((self=[super init])) {
		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"buttons.plist"];
		
		CGSize s = [[CCDirector sharedDirector] winSize];
		CCSprite *background = [BackgroundUtils genBackground];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            background.position = ccp(512, 384);
        } else {
            background.position = ccp(s.width/2, s.height/2);
        }
		[self addChild:background z:-10];
        
        id rotate = [CCRotateBy actionWithDuration:3.0f angle:360.0f];
        
		id seq = [CCSequence actions: rotate, nil];
        
		CCMenuItem *gameLoadingItem = [SoundMenuItem itemFromNormalSpriteFrameName:@"umbrella.png" selectedSpriteFrameName:@"umbrella.png" target:nil selector:nil];
        gameLoadingItem.isEnabled = NO;
		CCMenu *menuGameLoading = [CCMenu menuWithItems: gameLoadingItem, nil];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            menuGameLoading.position = ccp(512, 384);
        } else {
            menuGameLoading.position = ccp(s.width/2, s.height/2);
        }
        [gameLoadingItem runAction:[CCRepeatForever actionWithAction:seq]];
		[self addChild:menuGameLoading];
        
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background-music.MP3"];
	}
	
	return self;
}

@end
