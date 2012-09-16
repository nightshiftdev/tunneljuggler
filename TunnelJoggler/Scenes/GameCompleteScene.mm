//
//  GameCompleteScene.mm
//  TunnelJuggler
//
//  Created by pawel on 4/21/11.
//  Copyright 2011 __etcApps__. All rights reserved.
//

#import "GameCompleteScene.h"
#import "BackgroundUtils.h"
#import "SoundMenuItem.h"
#import "ChallengeScene.h"

@interface  GameCompleteScene()
@property (retain, nonatomic, readwrite) Level* currentLevel;
@property (assign, nonatomic, readwrite) BOOL pointsLevelChallenge;
@property (assign, nonatomic, readwrite) BOOL timeLevelChallenge;
@end


@implementation GameCompleteScene

@synthesize currentLevel = _currentLevel;
@synthesize pointsLevelChallenge;
@synthesize timeLevelChallenge;

+(id) scene {
	CCScene *scene = [CCScene node];
	id child = [GameCompleteScene node];
	
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
        
        CCSprite *clownBody = [CCSprite spriteWithSpriteFrameName:@"clown-body.png"];
        [clownBody setPosition:ccp(s.width/1.9, s.height/2.2)];
        [self addChild:clownBody z:2];
        
        CCSprite *happyClown = [CCSprite spriteWithSpriteFrameName:@"clown-happy.png"];
        [happyClown setPosition:ccp(s.width/1.4, s.height/2.2)];
        [self addChild:happyClown z:2];
        
        CCSprite *experience = [CCSprite spriteWithSpriteFrameName:@"experience-on.png"];
        [experience setPosition:ccp(s.width/4.0, s.height/1.8)];
        [self addChild:experience z:2];
        id scaleExperienceDown = [CCScaleTo actionWithDuration:0.5f scale:1.0f];
        id scaleExperienceUp = [CCScaleTo actionWithDuration:0.5f scale:2.0f];
        id seq = [CCSequence actions:scaleExperienceDown, scaleExperienceUp, nil];
        [experience runAction:[CCRepeatForever actionWithAction:seq]];
        
        double delayInSeconds = 3.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.1f scene:[ChallengeScene scene]]];
        });
	}
	
	return self;
}

- (void)dealloc {
    [super dealloc];
}
@end
