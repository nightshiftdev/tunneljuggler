//
//  HUD.m
//  TunnelJoggler
//
//  Created by pawel on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Game.h"
#import "HUD.h"
#import "SoundMenuItem.h"

@implementation HUD

+(id) HUDWithGameNode:(Game*)game {
	return [[[self alloc] initWithGameNode:game] autorelease];
}

-(id) initWithGameNode:(Game*)game {
	if( (self=[super init])) {
		self.isTouchEnabled = YES;
		game_ = game;
        
		CGSize s = [[CCDirector sharedDirector] winSize];
		
		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"buttons.plist"];
//		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"sprites.plist"];
		
		CCLayerColor *color = [CCLayerColor layerWithColor:ccc4(32,32,32,32) width:40 height:s.height];
		[color setPosition:ccp(s.width-40,0)];
		[self addChild:color z:0];
        
        // Menu Button
		CCMenuItem *itemPause = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-pause-normal.png" selectedSpriteFrameName:@"btn-pause-selected.png" target:self selector:@selector(onButtonPausePressed:)];
		CCMenu *menu = [CCMenu menuWithItems:itemPause,nil];
		[self addChild:menu z:1];
		[menu setPosition:ccp(s.width-20, 300)];
	}
	return self;
}

-(void) gameOver:(BOOL)didWin touchedFatalObject:(BOOL) fatalObjectTouched {
    
}

-(void) onUpdateScore:(int)newScore {
    
} 

-(void) pause {
	CGSize s = [[CCDirector sharedDirector] winSize];
	CCMenuItem *item0 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-small-play-normal.png" selectedSpriteFrameName:@"btn-small-play-selected.png" target:self selector:@selector(onResumePressed:)];
	CCMenuItem *item1 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-try-again-normal.png" selectedSpriteFrameName:@"btn-try-again-selected.png" target:self selector:@selector(onPlayAgainPressed:)];
	CCMenuItem *item2 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-exit-normal.png" selectedSpriteFrameName:@"btn-exit-selected.png" target:self selector:@selector(onMainMenuPressed:)];
	pauseMenu_ = [CCMenu menuWithItems:item0, item1, item2, nil];
	[pauseMenu_ alignItemsVertically];
	[pauseMenu_ setPosition:ccp(s.width/2, s.height/2)];
	
	[self addChild:pauseMenu_ z:10];
}

-(void) onButtonPausePressed:(id)sender {
//	if (!isPauseMenuDisplayed_ &&
//		!isGameOver_) {
//		isPauseMenuDisplayed_ = YES;
		[[CCDirector sharedDirector] pause];
		[self pause];
//	}
}

-(void) onResumePressed:(id)sender {
    
}

-(void) onPlayAgainPressed:(id)sender {
    
}

-(void) onMainMenuPressed:(id)sender {
    
}

@end
