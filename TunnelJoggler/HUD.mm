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
#import "GameCenterManager.h"
#import "Level.h"
#import "ChallengeScene.h"

@interface HUD()
@property (nonatomic, assign) BOOL isGameOver;
@property (nonatomic, assign) int score;
@property (assign, nonatomic, readwrite) BOOL isShowingHowToPlay;
@property (assign, nonatomic, readwrite) BOOL pointsLevelChallenge;
@property (assign, nonatomic, readwrite) BOOL timeLevelChallenge;
@property (retain, nonatomic, readwrite) Level* currentLevel;
@property (nonatomic, assign) int scoreToPassLevel;
-(void) setupCountDownTimer;
-(void) setupAdditionalScoreCounter;
-(void) resume;
@end

@implementation HUD

@synthesize isGameOver;
@synthesize score;
@synthesize isShowingHowToPlay;
@synthesize pointsLevelChallenge;
@synthesize timeLevelChallenge;
@synthesize currentLevel = _currentLevel;
@synthesize scoreToPassLevel;

+(id) HUDWithGameNode:(Game*)game {
	return [[[self alloc] initWithGameNode:game] autorelease];
}

-(id) initWithGameNode:(Game*)game {
	if( (self=[super init])) {
		self.isTouchEnabled = YES;
		game_ = game;
        
		CGSize s = [[CCDirector sharedDirector] winSize];
		
		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"buttons.plist"];
		
		CCLayerColor *color = [CCLayerColor layerWithColor:ccc4(0,0,0,0) width:80 height:s.height];
		[color setPosition:ccp(s.width-80,0)];
		[self addChild:color z:0];
        
        // Menu Button
		CCMenuItem *itemPause = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-pause-normal.png" selectedSpriteFrameName:@"btn-pause-selected.png" target:self selector:@selector(onButtonPausePressed:)];
		CCMenu *menu = [CCMenu menuWithItems:itemPause,nil];
		[self addChild:menu z:1];
		[menu setPosition:ccp(s.width-20, s.height-30)];
        self.isGameOver = NO;
        
        
        // Score
        self.score = [[[GameController sharedController] player].score intValue];
		scoreLabel_ = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%d", self.score] fntFile:@"sticky.fnt"];
		[scoreLabel_.texture setAliasTexParameters];
		[self addChild:scoreLabel_ z:1];
		[scoreLabel_ setPosition:ccp(s.width - 20, s.height/2)];
        scoreLabel_.rotation = 90;

        
        [self setupCountDownTimer];
        
        [self setupAdditionalScoreCounter];
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
        
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[CCDirector sharedDirector] pause];
            self.currentLevel = nil;
        });
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
    
    if (self.pointsLevelChallenge) {
        self.scoreToPassLevel += addScore;
        [_scoreChallengeLabel setString: [NSString stringWithFormat:@"%d ( %d )", self.scoreToPassLevel, [self.currentLevel.scoreToPass intValue]]];
        if (self.scoreToPassLevel >= [self.currentLevel.scoreToPass intValue]) {
            [self gameOver:YES touchedFatalObject:NO];
        }
    }
}

-(Level*)currentLevel {
    if (nil == _currentLevel) {
        Player *p = [[GameController sharedController] player];
        NSArray *levels = [[GameController sharedController] levels];
        _currentLevel = [levels objectAtIndex: [p.currentLevel intValue]];
    }
    return _currentLevel;
}

-(BOOL)pointsLevelChallenge {
    if(![self.currentLevel.mustReachEndOfLevelToPass boolValue] &&
       [self.currentLevel.scoreToPass intValue] > 0) {
        return YES;
    }
    return NO;
}

-(BOOL)timeLevelChallenge {
    if (![self.currentLevel.mustReachEndOfLevelToPass boolValue] &&
        [self.currentLevel.timeToSurviveToPass intValue] > 0) {
        return YES;
    }
    return NO;
}

-(void) setupCountDownTimer {
    if (self.timeLevelChallenge == YES) {
        int time = [self.currentLevel.timeToSurviveToPass intValue];
        _minutes = time / 60;
        _seconds = time - (_minutes * 60);
        CGSize s = [[CCDirector sharedDirector] winSize];
        NSString *counterLabelFormat = nil;
        if (_seconds < 10) {
            counterLabelFormat = [NSString stringWithFormat:@"%d : 0%d", _minutes, _seconds];
        } else {
            counterLabelFormat = [NSString stringWithFormat:@"%d : %d", _minutes, _seconds];
        }
        _timeLabel = [CCLabelBMFont labelWithString:counterLabelFormat fntFile:@"sticky.fnt"];
        [_timeLabel.texture setAliasTexParameters];
        [self addChild:_timeLabel z:1];
        [_timeLabel setPosition:ccp(s.width - 60, s.height/2)];
        _timeLabel.rotation = 90;
    }
}

-(void) setupAdditionalScoreCounter {
    if (self.pointsLevelChallenge == YES) {
        self.scoreToPassLevel = 0;
        CGSize s = [[CCDirector sharedDirector] winSize];
        _scoreChallengeLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"%d ( %d )", self.scoreToPassLevel, [self.currentLevel.scoreToPass intValue]] fntFile:@"sticky.fnt"];
        [_scoreChallengeLabel.texture setAliasTexParameters];
        [self addChild:_scoreChallengeLabel z:1];
        [_scoreChallengeLabel setPosition:ccp(s.width - 60, s.height/2)];
        _scoreChallengeLabel.rotation = 90;
    }
}

-(void) onUpdateCountDownTimer {
    if (_seconds <= 0 && _minutes > 0) {
        _seconds = 59;
        _minutes--;
    } else if (_seconds > 0) {
        _seconds--;
    }
    if (_seconds < 10) {
        [_timeLabel setString: [NSString stringWithFormat:@"%d : 0%d", _minutes, _seconds]];
    } else {
        [_timeLabel setString: [NSString stringWithFormat:@"%d : %d", _minutes, _seconds]];
    }
    
    if (_minutes == 0 && _seconds == 0) {
        [self gameOver:YES touchedFatalObject:NO];
    }
}

-(void) pause {
	CGSize s = [[CCDirector sharedDirector] winSize];
	CCMenuItem *item2 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-small-play-normal.png" selectedSpriteFrameName:@"btn-small-play-selected.png" target:self selector:@selector(onResumePressed:)];
	CCMenuItem *item1 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-try-again-normal.png" selectedSpriteFrameName:@"btn-try-again-selected.png" target:self selector:@selector(onPlayAgainPressed:)];
	CCMenuItem *item0 = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-exit-normal.png" selectedSpriteFrameName:@"btn-exit-selected.png" target:self selector:@selector(onMainMenuPressed:)];
	menu_ = [CCMenu menuWithItems:item0, item1, item2, nil];
	[menu_ alignItemsHorizontallyWithPadding: 25.0];
	[menu_ setPosition:ccp(s.width/2, s.height/2)];
	[self addChild:menu_ z:10];
    [[CCDirector sharedDirector] pause];
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
    NSString *fingerGraphicName =  @"finger.png";
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
        fingerGraphicName = @"finger_ipad.png";
    }
	CCMenuItem *item0 = [SoundMenuItem itemFromNormalSpriteFrameName:fingerGraphicName selectedSpriteFrameName:fingerGraphicName target:nil selector:nil];
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
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.1f scene:[ChallengeScene scene]]];
}

@end
