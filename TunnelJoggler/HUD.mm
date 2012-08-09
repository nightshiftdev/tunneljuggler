//
//  HUD.m
//  TunnelJoggler
//
//  Created by pawel on 5/18/12.
//  Copyright (c) 2012 Pawel Kijowski. All rights reserved.
//

#import "Game.h"
#import "HUD.h"
#import "SoundMenuItem.h"
#import "MainScene.h"
#import "GameController.h"

@interface HUD()
@property (nonatomic, assign) BOOL isGameOver;
@property (nonatomic, assign) int score;
@property (assign, nonatomic, readwrite) BOOL isShowingHowToPlay;
@end

@implementation HUD

@synthesize isGameOver;
@synthesize score;
@synthesize isShowingHowToPlay;

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
        self.score = [[[GameController sharedController] player].score intValue];
		scoreLabel_ = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%d", self.score] fntFile:@"sticky.fnt"];
		[scoreLabel_.texture setAliasTexParameters];
		[self addChild:scoreLabel_ z:1];
		[scoreLabel_ setPosition:ccp(s.width - 20, s.height/2)];
        scoreLabel_.rotation = 90;
	}
	return self;
}

-(void) savePlayerScoreAndIncreaseExperienceLevel {
    Player *player = [[GameController sharedController] player];
    int nextLevel = [player.currentLevel intValue] + 1;
    int experienceLevel = [player.experienceLevel intValue] + 1;
    NSArray *levels = [[GameController sharedController] levels];
    if (nextLevel >= [levels count]) {
        experienceLevel += 100;
    }
    player.experienceLevel =  [NSNumber numberWithInt: experienceLevel];
    player.score = [NSNumber numberWithInt: self.score];
    [GameController sharedController].player = player;
}

-(void) advancePlayerToNextLevel {
    Player *player = [[GameController sharedController] player];
    int nextLevel = [player.currentLevel intValue] + 1;
    NSArray *levels = [[GameController sharedController] levels];
    if (nextLevel >= [levels count]) {
        nextLevel = 0;
    }
    player.currentLevel = [NSNumber numberWithInt: nextLevel];
    [GameController sharedController].player = player;
}

-(void) gameOver:(BOOL)didWin touchedFatalObject:(BOOL) fatalObjectTouched {
    if (!self.isGameOver) {
        self.isGameOver = YES;
        [[CCDirector sharedDirector] pause];
        CCMenuItem *item0 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-exit-normal.png" selectedSpriteFrameName:@"btn-exit-selected.png" target:self selector:@selector(onMainMenuPressed:)];
        CCMenuItem *item2, *item1 = nil;
        if (fatalObjectTouched) {
            item1 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-try-again-normal.png" selectedSpriteFrameName:@"btn-try-again-selected.png" target:self selector:@selector(onPlayAgainPressed:)];
            item2 = [SoundMenuItem itemFromNormalSpriteFrameName:@"info-level-failed.png" selectedSpriteFrameName:@"info-level-failed.png" target:nil selector:nil];
        } else {
            item1 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-small-play-normal.png" selectedSpriteFrameName:@"btn-small-play-selected.png" target:self selector:@selector(onNextLevelPressed:)];
            item2 = [SoundMenuItem itemFromNormalSpriteFrameName:@"info-level-passed.png" selectedSpriteFrameName:@"info-level-passed.png" target:nil selector:nil];
        }
        
        if (!fatalObjectTouched && didWin) {
            [self savePlayerScoreAndIncreaseExperienceLevel];
        }
        
        [item2 setIsEnabled:NO];
        menu_ = [CCMenu menuWithItems:item0, item1, item2, nil];
        CGSize s = [[CCDirector sharedDirector] winSize];
        [menu_ alignItemsHorizontallyWithPadding: 25.0];
        [menu_ setPosition:ccp(s.width/2, s.height/2)];
        [self addChild:menu_ z:10];
    }
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

-(void) showHowToPlay {
    self.isShowingHowToPlay = YES;
	CGSize s = [[CCDirector sharedDirector] winSize];
    id moveRight = [CCMoveBy actionWithDuration:1.0 position:CGPointMake(0, -50.0)];
    id moveLeft = [CCMoveBy actionWithDuration:2.0 position:CGPointMake(0, 100.0)];
    id seq = [CCSequence actions:moveRight, moveLeft, moveRight, nil];
	CCMenuItem *item0 = [SoundMenuItem itemFromNormalSpriteFrameName:@"finger.png" selectedSpriteFrameName:@"finger.png" target:nil selector:nil];
    item0.isEnabled = NO;
	menu_ = [CCMenu menuWithItems:item0, nil];
    [item0 runAction:[CCRepeatForever actionWithAction:seq]];
	[menu_ alignItemsHorizontallyWithPadding: 25.0];
	[menu_ setPosition:ccp(20.0, s.height/2)];
	[self addChild:menu_ z:10];
}

-(void) dismissHowToPlay:(id)sender {
    if (self.isShowingHowToPlay) {
        self.isShowingHowToPlay = NO;
    }
    [self resume];
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
	[[CCDirector sharedDirector] replaceScene: [CCTransitionFade transitionWithDuration:0.1f scene:[[game_ class] scene]]];
}

-(void) onMainMenuPressed:(id)sender {
	if ([[CCDirector sharedDirector] isPaused]) {
		[[CCDirector sharedDirector] resume];
	}
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.1f scene:[MainScene scene]]];
}

-(void) onNextLevelPressed:(id)sender {
    if ([[CCDirector sharedDirector] isPaused]) {
		[[CCDirector sharedDirector] resume];
	}
    [self advancePlayerToNextLevel];
    [[CCDirector sharedDirector] replaceScene: [CCTransitionFade transitionWithDuration:0.1f scene:[[game_ class] scene]]];
}

@end
