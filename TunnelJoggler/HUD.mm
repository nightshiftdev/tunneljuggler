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

@interface HUD()
@property (nonatomic, assign) BOOL isGameOver;
@property (nonatomic, assign) int score;
@end

@implementation HUD

@synthesize isGameOver;
@synthesize score;

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
		
		CCLayerColor *color = [CCLayerColor layerWithColor:ccc4(0,0,0,0) width:40 height:s.height];
		[color setPosition:ccp(s.width-40,0)];
		[self addChild:color z:0];
        
        // Menu Button
		CCMenuItem *itemPause = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-pause-normal.png" selectedSpriteFrameName:@"btn-pause-selected.png" target:self selector:@selector(onButtonPausePressed:)];
		CCMenu *menu = [CCMenu menuWithItems:itemPause,nil];
		[self addChild:menu z:1];
		[menu setPosition:ccp(s.width-20, s.height-30)];
        self.isGameOver = NO;
        
        
        // Score Points
		scoreLabel_ = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%d", self.score] fntFile:@"sticky.fnt"];
		[scoreLabel_.texture setAliasTexParameters];
		[self addChild:scoreLabel_ z:1];
		[scoreLabel_ setPosition:ccp(s.width - 20, s.height/2)];
        scoreLabel_.rotation = 90;
	}
	return self;
}

-(void) gameOver:(BOOL)didWin touchedFatalObject:(BOOL) fatalObjectTouched {
    self.isGameOver = YES;
    [[CCDirector sharedDirector] pause];
    CGSize s = [[CCDirector sharedDirector] winSize];
	CCMenuItem *item1 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-try-again-normal.png" selectedSpriteFrameName:@"btn-try-again-selected.png" target:self selector:@selector(onPlayAgainPressed:)];
	CCMenuItem *item0 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-exit-normal.png" selectedSpriteFrameName:@"btn-exit-selected.png" target:self selector:@selector(onMainMenuPressed:)];
	menu_ = [CCMenu menuWithItems:item0, item1, nil];
	[menu_ alignItemsHorizontallyWithPadding: 25.0];
	[menu_ setPosition:ccp(s.width/2, s.height/2)];
	[self addChild:menu_ z:10];
}

-(void) onUpdateScore:(int)addScore {
	self.score += addScore;
	[scoreLabel_ setString: [NSString stringWithFormat:@"%d", self.score]];
	[scoreLabel_ stopAllActions];
	id scaleTo = [CCScaleTo actionWithDuration:0.1f scale:1.2f];
	id scaleBack = [CCScaleTo actionWithDuration:0.1f scale:1];
	id seq = [CCSequence actions:scaleTo, scaleBack, nil];
	[scoreLabel_ runAction:seq];
}

-(void) pause {
    [[CCDirector sharedDirector] pause];
	CGSize s = [[CCDirector sharedDirector] winSize];
	CCMenuItem *item2 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-small-play-normal.png" selectedSpriteFrameName:@"btn-small-play-selected.png" target:self selector:@selector(onResumePressed:)];
	CCMenuItem *item1 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-try-again-normal.png" selectedSpriteFrameName:@"btn-try-again-selected.png" target:self selector:@selector(onPlayAgainPressed:)];
	CCMenuItem *item0 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-exit-normal.png" selectedSpriteFrameName:@"btn-exit-selected.png" target:self selector:@selector(onMainMenuPressed:)];
	menu_ = [CCMenu menuWithItems:item0, item1, item2, nil];
	[menu_ alignItemsHorizontallyWithPadding: 25.0];
	[menu_ setPosition:ccp(s.width/2, s.height/2)];
	[self addChild:menu_ z:10];
}

-(void)resume {
    [self removeChild:menu_ cleanup: YES];
    [[CCDirector sharedDirector] resume];
}

-(void) onButtonPausePressed:(id)sender {
	if (![[CCDirector sharedDirector] isPaused] &&
        !self.isGameOver) {
		[self pause];
	} else if (!self.isGameOver) {
        [self resume];
    }
}

-(void) onResumePressed:(id)sender {
    [self resume];
}

-(void) onPlayAgainPressed:(id)sender {
    if ([[CCDirector sharedDirector] isPaused]) {
		[[CCDirector sharedDirector] resume];
	}
    [game_ resetGame];
	[[CCDirector sharedDirector] replaceScene: [CCTransitionFade transitionWithDuration:0.1f scene:[[game_ class] scene]]];
}

-(void) onMainMenuPressed:(id)sender {
    
}

@end
