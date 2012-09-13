//
//  SplashScene.mm
//  TunnelJuggler
//
//  Created by pawel on 4/21/11.
//  Copyright 2011 __etcApps__. All rights reserved.
//

#import "ChallengeScene.h"
#import "BackgroundUtils.h"
#import "SoundMenuItem.h"
#import "GameController.h"
#import "Game.h"
#import "Level.h"
#import "Player.h"

@interface ChallengeScene()
@property (retain, nonatomic, readwrite) Level* currentLevel;
@property (assign, nonatomic, readwrite) BOOL pointsLevelChallenge;
@property (assign, nonatomic, readwrite) BOOL timeLevelChallenge;
@end


@implementation ChallengeScene

@synthesize currentLevel = _currentLevel;
@synthesize pointsLevelChallenge;
@synthesize timeLevelChallenge;

+(id) scene {
	CCScene *scene = [CCScene node];
	id child = [ChallengeScene node];
	
	[scene addChild:child];
	return scene;
}

-(id) init {
	if((self=[super init])) {
        NSString *buttonsPlist = @"buttons.plist";
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            buttonsPlist = @"buttons-ipad.plist";
        }
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:buttonsPlist];
		
		CGSize s = [[CCDirector sharedDirector] winSize];
		CCSprite *background = [BackgroundUtils genBackground];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            background.position = ccp(512, 384);
        } else {
            background.position = ccp(s.width/2, s.height/2);
        }
		[self addChild:background z:-10];
        
        CCSprite *challengeBackground = [CCSprite spriteWithSpriteFrameName:@"challenge-background.png"];
        challengeBackground.position = ccp(s.width/2, s.height/2);
        [self addChild:challengeBackground z:1];
        
        NSString *challengeText = nil;
        CCSprite *challengeIcon = nil;
        if (self.timeLevelChallenge) {
            int time = [self.currentLevel.timeToSurviveToPass intValue];
            int minutes = time / 60;
            int seconds = time - (minutes * 60);
            challengeIcon = [CCSprite spriteWithSpriteFrameName:@"time-challenge.png"];
            if (seconds < 10) {
                challengeText = [NSString stringWithFormat:@" %d : 0%d ", minutes, seconds];
            } else {
                challengeText = [NSString stringWithFormat:@" %d : %d ", minutes, seconds];
            }
            
        } else if (self.pointsLevelChallenge) {
            challengeIcon = [CCSprite spriteWithSpriteFrameName:@"points-challenge.png"];
            challengeText = [NSString stringWithFormat:@" (%d) ", [self.currentLevel.scoreToPass intValue]];
        } else {
            challengeIcon = [CCSprite spriteWithSpriteFrameName:@"length-challenge.png"];
            challengeText = [NSString stringWithFormat:@" %d ", [self.currentLevel.length intValue] * 60];
        }
        challengeIcon.position = ccp(s.width/1.6, s.height/2.3);
        [self addChild:challengeIcon z:2];
        
        float fontSize = 60.0;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            fontSize = 120.0;
        }
        CCLabelTTF *challengeLabel = [CCLabelTTF labelWithString:challengeText fontName:@"BosoxRevised.ttf" fontSize:fontSize];
        challengeLabel.color = ccc3(204, 0, 0);
        [self addChild:challengeLabel z:2];
        [challengeLabel setPosition:ccp(s.width/4, s.height/1.9)];
        challengeLabel.rotation = 90;
        
        double delayInSeconds = 1.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.1f scene:[Game scene]]];
        });
	}
	
	return self;
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

- (void)dealloc {
    [super dealloc];
}
@end
