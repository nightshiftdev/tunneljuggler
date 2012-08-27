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

@synthesize preloader = _preloader;
@synthesize jugglingAction = _jugglingAction;

+(id) scene {
	CCScene *scene = [CCScene node];
	id child = [SplashScene node];
	
	[scene addChild:child];
	return scene;
}

-(id) init {
	if((self=[super init])) {
        
        NSString *buttonsPlist = @"buttons.plist";
        NSString *preloaderPlist = @"preloader.plist";
        NSString *preloaderPng = @"preloader.png";
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            buttonsPlist = @"buttons-ipad.plist";
            preloaderPlist = @"preloader-ipad.plist";
            preloaderPng = @"preloader-ipad.png";
        }
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:buttonsPlist];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:preloaderPlist];
        
        
        CCSpriteBatchNode *spriteSheet = [CCSpriteBatchNode batchNodeWithFile:preloaderPng];
        [self addChild:spriteSheet];
        
        // Load up the frames of our animation
        NSMutableArray *juggleAnimFrames = [NSMutableArray array];
        for(int i = 1; i <= 40; ++i) {
            [juggleAnimFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:[NSString stringWithFormat:@"prealoader%d.png", i]]];
        }
        CCAnimation *jugglingAnim = [CCAnimation animationWithFrames:juggleAnimFrames delay:0.05f];
        
        CGSize s = [[CCDirector sharedDirector] winSize];
        self.preloader = [CCSprite spriteWithSpriteFrameName:@"prealoader1.png"];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            _preloader.position = ccp(400, 384);
        } else {
            _preloader.position = ccp(s.width/2.5, s.height/2);
        }
        self.jugglingAction = [CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:jugglingAnim restoreOriginalFrame:NO]];
        _preloader.rotation = 90;
        [_preloader runAction:_jugglingAction];
        [spriteSheet addChild:_preloader];
        
        CCMenuItem *itemTitle = [SoundMenuItem itemFromNormalSpriteFrameName:@"main-title.png" selectedSpriteFrameName:@"main-title.png" target:nil selector:nil];
        itemTitle.isEnabled = NO;
        CCMenu *menuTitle = [CCMenu menuWithItems: itemTitle, nil];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            menuTitle.position = ccp(600, 384);
        } else {
            menuTitle.position = ccp(s.width/1.5, s.height/2);
        }
        [self addChild:menuTitle z:2];
        
		
		CCSprite *background = [BackgroundUtils genBackground];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            background.position = ccp(512, 384);
        } else {
            background.position = ccp(s.width/2, s.height/2);
        }
		[self addChild:background z:-10];
        
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background-music.MP3"];
	}
	
	return self;
}

- (void) dealloc
{
	self.preloader = nil;
    self.jugglingAction = nil;
	[super dealloc];
}

@end
