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
		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"buttons.plist"];
		
		CGSize s = [[CCDirector sharedDirector] winSize];
		CCSprite *background = [BackgroundUtils genBackground];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            background.position = ccp(512, 384);
        } else {
            background.position = ccp(s.width/2, s.height/2);
        }
		[self addChild:background z:-10];
        
        NSString *challengeText = @"L E N G T H  C H A L L E N G E";
        if (self.timeLevelChallenge) {
            challengeText = @"T I M E  C H A L L E N G E";
        } else if (self.pointsLevelChallenge) {
            challengeText = @"P O I N T S  C H A L L E N G E";
        }
        
        CCLabelBMFont *challengeLabel = [CCLabelBMFont labelWithString:challengeText fntFile:@"sticky.fnt"];
        [challengeLabel.texture setAliasTexParameters];
        [self addChild:challengeLabel z:1];
        [challengeLabel setPosition:ccp(s.width/2, s.height/2)];
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
@end
