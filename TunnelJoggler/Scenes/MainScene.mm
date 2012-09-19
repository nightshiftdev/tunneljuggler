//
//  MainScene.mm
//  StickyET
//
//  Created by pawel on 4/21/11.
//  Copyright 2011 __etcApps__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MainScene.h"
#import "SoundMenuItem.h"
#import "Game.h"
#import "SimpleAudioEngine.h"
#import "GameController.h"
#import "BackgroundUtils.h"
#import "ChallengeScene.h"

@interface MainScene()
- (void) setUserPictureForNormalState: (CCSprite *) normalStateSprite selectedState: (CCSprite *) selectedStateSprite;
- (void) showLeaderboard;
- (void) createScoreLabelWithScore: (int) score;
- (void) createCurrentLevelLabelWithLevel: (int) level;
- (void) createExperienceDisplay: (int) experienceLevel;
- (void) createVersionLabel;

@property (retain, nonatomic, readwrite) CCMenuItem *itemUserPicture;
@property (retain, nonatomic, readwrite) CCMenu *playerPictureMenu;
@end


@implementation MainScene

@synthesize itemUserPicture;
@synthesize playerPictureMenu;

+(id) scene {
	CCScene *scene = [CCScene node];
	id child = [MainScene node];
	
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
		background.position = ccp(s.width/2, s.height/2);
		[self addChild:background z:-10];
        
        Player *p = [[GameController sharedController] player];
        if (nil != p) {
            // main frame
            CCMenuItem *itemFrame = [SoundMenuItem itemFromNormalSpriteFrameName:@"main-frame.png" selectedSpriteFrameName:@"main-frame.png" target:nil selector:nil];
            itemFrame.isEnabled = NO;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
                itemFrame.scale = 0.88;
            }
            CCMenu *menuFrame = [CCMenu menuWithItems: itemFrame, nil];
            menuFrame.position = ccp(s.width/2, s.height/2);
            [self addChild:menuFrame z:0];
            
            id scaleTo = [CCScaleTo actionWithDuration:0.5f scale:0.9f];
            id scaleBack = [CCScaleTo actionWithDuration:0.5f scale:1.0f];
            id rotateLeft = [CCRotateBy actionWithDuration:0.1f angle:5.0f];
            id rotateRight = [CCRotateBy actionWithDuration:0.2f angle:-10.0f];
            
            id seq = [CCSequence actions:scaleTo, scaleBack, rotateLeft, rotateRight, rotateLeft, nil];
            
            //Play button
            CCMenuItem *itemPlay = [SoundMenuItem itemFromNormalSpriteFrameName:@"start-game-off.png" selectedSpriteFrameName:@"start-game-on.png" target:self selector:@selector(playGame:)];
            CCMenu *menuPlay = [CCMenu menuWithItems: itemPlay, nil];
            menuPlay.position = ccp(s.width/2.4, s.height/2);
            [itemPlay runAction:[CCRepeatForever actionWithAction:seq]];
            [self addChild:menuPlay];
            
            //Clown face
            CCSprite *spriteFromImageNormal = [CCSprite spriteWithSpriteFrameName: @"clown-happy.png"];
            CCSprite *spriteFromImageSelected = [CCSprite spriteWithSpriteFrameName: @"clown-happy.png"];
            spriteFromImageNormal.scale = 0.55;
            spriteFromImageSelected.scale = 0.55;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                spriteFromImageNormal.scale = 0.65;
                spriteFromImageSelected.scale = 0.65;
            }
            [self setUserPictureForNormalState: spriteFromImageNormal
                                 selectedState: spriteFromImageSelected];
            
            //Score ribbon
            CCMenuItem *itemScoreRibbon = [SoundMenuItem itemFromNormalSpriteFrameName:@"score-frame.png" selectedSpriteFrameName:@"score-frame.png" target:nil selector:nil];
            itemScoreRibbon.isEnabled = NO;
            CCMenu *menuScoreRibbon = [CCMenu menuWithItems: itemScoreRibbon, nil];
            menuScoreRibbon.position = ccp(s.width/1.58, s.height/2);
            [self addChild:menuScoreRibbon z:4];
            
            // Score
            [self createScoreLabelWithScore:[p.score intValue]];
            
            // Experience
            [self createExperienceDisplay:[p.experienceLevel intValue]];
            
            // Current level
            [self createCurrentLevelLabelWithLevel:[p.currentLevel intValue]];
            
            [self createVersionLabel];
            
            //Game center
            CCMenuItem *itemGameCenter = [SoundMenuItem itemFromNormalSpriteFrameName:@"game-center-off.png" selectedSpriteFrameName:@"game-center-on.png" target:self selector:@selector(highScoreGameCenter:)];
            CCMenu *menuGameCenter = [CCMenu menuWithItems: itemGameCenter, nil];
            menuGameCenter.position = ccp(s.width/9, s.height/2);
            id scaleGameCenterButtonTo = [CCScaleTo actionWithDuration:1.0f scale:0.95f];
            id scaleGameCenterButtonBack = [CCScaleTo actionWithDuration:1.0f scale:1.0f];
            seq = [CCSequence actions:scaleGameCenterButtonTo, scaleGameCenterButtonBack, nil];
            [itemGameCenter runAction:[CCRepeatForever actionWithAction:seq]];
            [self addChild:menuGameCenter];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reloadGameData:)
                                                         name:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                                       object:[GameController sharedController].psc];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(reloadGameData:)
                                                         name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                       object:[GameController sharedController].psc];
        }
	}
	
	return self;
}

-(void)onExit {
    [self unscheduleUpdate];
    [self unscheduleAllSelectors];
    [super onExit];
}

- (void)dealloc {
    self.playerPictureMenu = nil;
    self.itemUserPicture = nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

-(void) playGame:(id)sender {
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.1f scene:[ChallengeScene scene]]];
}

- (void) createScoreLabelWithScore: (int) score {
    if (nil != _scoreLabel) {
        [self removeChild: _scoreLabel cleanup: YES];
    }
    float fontSize = 28.0;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        fontSize = 56.0;
    }
    _scoreLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@" %d ", score] fontName:@"BosoxRevised.ttf" fontSize:fontSize];
    _scoreLabel.color = ccc3(204, 0, 0);
    [self addChild:_scoreLabel z:5];
    CGSize s = [[CCDirector sharedDirector] winSize];
    [_scoreLabel setPosition:ccp(s.width/1.55, s.height/2)];
    _scoreLabel.rotation = 90;
}

- (void) createCurrentLevelLabelWithLevel: (int) level {
    if (nil != _currentLevelLabel) {
        [self removeChild:_currentLevelLabel cleanup: YES];
    }
    float fontSize = 26.0;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        fontSize = 52.0;
    }
    _currentLevelLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@" %d ", level + 1] fontName:@"BosoxRevised.ttf" fontSize:fontSize];
    _currentLevelLabel.color = ccc3(255, 255, 255);
    [self addChild:_currentLevelLabel z:5];
    CGSize s = [[CCDirector sharedDirector] winSize];
    [_currentLevelLabel setPosition:ccp(s.width/2.48, s.height/2)];
    _currentLevelLabel.rotation = 90;
}

- (void) createVersionLabel {
    float fontSize = 10.0;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        fontSize = 20.0;
    }
    CCLabelTTF *verLabel = [CCLabelTTF labelWithString:@"v1.0.0" fontName:@"BosoxRevised.ttf" fontSize:fontSize];
    verLabel.color = ccc3(255, 255, 255);
    [self addChild:verLabel z:5];
    CGSize s = [[CCDirector sharedDirector] winSize];
    [verLabel setPosition:ccp(fontSize, s.height/2)];
    verLabel.rotation = 90;
}

- (void) createExperienceDisplay: (int) experienceLevel {
    if (nil != _experienceDisplayLevel0) {
        [self removeChild:_experienceDisplayLevel0 cleanup:YES];
    }
    
    _experienceDisplayLevel0 = [SoundMenuItem itemFromNormalSpriteFrameName:@"experience-on.png" selectedSpriteFrameName:@"experience-on.png" disabledSpriteFrameName:@"experience-off.png" target:nil selector:nil];
    if (experienceLevel >= 10) {
        _experienceDisplayLevel0.isEnabled = YES;
    } else {
        _experienceDisplayLevel0.isEnabled = NO;
    }
    
    _experienceDisplayLevel1 = [SoundMenuItem itemFromNormalSpriteFrameName:@"experience-on.png" selectedSpriteFrameName:@"experience-on.png" disabledSpriteFrameName:@"experience-off.png" target:nil selector:nil];
    if (experienceLevel >= 100) {
        _experienceDisplayLevel1.isEnabled = YES;
    } else {
        _experienceDisplayLevel1.isEnabled = NO;
    }
    
    _experienceDisplayLevel2 = [SoundMenuItem itemFromNormalSpriteFrameName:@"experience-on.png" selectedSpriteFrameName:@"experience-off.png" disabledSpriteFrameName:@"experience-off.png" target:nil selector:nil];
    if (experienceLevel >= 200) {
        _experienceDisplayLevel2.isEnabled = YES;
    } else {
        _experienceDisplayLevel2.isEnabled = NO;
    }

    _experienceDisplayLevel3 = [SoundMenuItem itemFromNormalSpriteFrameName:@"experience-on.png" selectedSpriteFrameName:@"experience-on.png" disabledSpriteFrameName:@"experience-off.png" target:nil selector:nil];
    if (experienceLevel >= 300) {
        _experienceDisplayLevel3.isEnabled = YES;
    } else {
        _experienceDisplayLevel3.isEnabled = NO;
    }
    
    _experienceDisplayLevel4 = [SoundMenuItem itemFromNormalSpriteFrameName:@"experience-on.png" selectedSpriteFrameName:@"experience-on.png" disabledSpriteFrameName:@"experience-off.png" target:nil selector:nil];
    if (experienceLevel >= 400) {
        _experienceDisplayLevel4.isEnabled = YES;
    } else {
        _experienceDisplayLevel4.isEnabled = NO;
    }
    
    CCMenu *menuExperienceLevel = [CCMenu menuWithItems: _experienceDisplayLevel0,
                                   _experienceDisplayLevel1,
                                   _experienceDisplayLevel2,
                                   _experienceDisplayLevel3,
                                   _experienceDisplayLevel4,
                                   nil];
    [menuExperienceLevel alignItemsVertically];
    
    CGSize s = [[CCDirector sharedDirector] winSize];
    menuExperienceLevel.position = ccp(s.width/1.75, s.height/2);
    [self addChild:menuExperienceLevel z:4];
    
}

-(void)reloadGameData:(id)sender {
#ifdef DEBUG
    Player *p = [[GameController sharedController] player];
    NSLog(@"MainScene reloadGameData called.");
    NSLog(@"MainScene reloadGameData score %d", [p.score intValue]);
    NSLog(@"MainScene reloadGameData current level %d", [p.currentLevel intValue]);
    NSLog(@"MainScene reloadGameData experience level %d", [p.experienceLevel intValue]);
#endif
    [self scheduleUpdate];
}

- (void)highScoreGameCenter:(id)sender {
    if ([[GameCenterManager sharedManager] isLocalUserAuthenticated]) {
        [self showLeaderboard];
    } else {
        if([GameCenterManager isGameCenterAvailable]) {
            [[GameCenterManager sharedManager] authenticateLocalUser];
        }
    }
}

- (void) setUserPictureForNormalState: (CCSprite *) normalStateSprite selectedState: (CCSprite *) selectedStateSprite {
    [self.itemUserPicture stopAllActions];
    [self removeChild: self.playerPictureMenu cleanup: YES];
    
    id rotateLeft = [CCRotateBy actionWithDuration:0.2f angle:-1.0f];
    id rotateRight = [CCRotateBy actionWithDuration:0.4f angle:2.0f];
    id scaleTo = [CCScaleTo actionWithDuration:0.5f scale:0.98f];
    id scaleBack = [CCScaleTo actionWithDuration:0.5f scale:1.0f];
    
    id seq = [CCSequence actions:rotateLeft, rotateRight, rotateLeft, scaleTo, scaleBack, nil];
    
    CGSize s = [[CCDirector sharedDirector] winSize];
    self.itemUserPicture = [SoundMenuItem itemFromNormalSprite:normalStateSprite
                                                selectedSprite:selectedStateSprite
                                                        target:self
                                                      selector:nil
                            ];
    self.itemUserPicture.isEnabled = NO;
    self.playerPictureMenu = [CCMenu menuWithItems: self.itemUserPicture, nil];
    self.playerPictureMenu.position = ccp(s.width/1.21, s.height/1.65);
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.playerPictureMenu.position = ccp(s.width/1.22, s.height/1.75);
    }
    self.playerPictureMenu.isTouchEnabled = YES;
    [itemUserPicture runAction:[CCRepeatForever actionWithAction:seq]];
    [self addChild:self.playerPictureMenu z:3];
}

#pragma mark GameCenter View Controllers
- (void) showLeaderboard
{
	GKLeaderboardViewController *leaderboardController = [[GKLeaderboardViewController alloc] init];
	if (leaderboardController != NULL) 
	{
		leaderboardController.category = kTunnelJugglerLeaderboardID;
		leaderboardController.timeScope = GKLeaderboardTimeScopeAllTime;
		leaderboardController.leaderboardDelegate = self; 
		[[[UIApplication sharedApplication] delegate].window.rootViewController presentModalViewController: leaderboardController animated: YES];
	}
}

#pragma mark -
#pragma mark GKLeaderboardViewControllerDelegate

- (void)leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	[[[UIApplication sharedApplication] delegate].window.rootViewController dismissModalViewControllerAnimated: YES];
	[viewController release];
}

- (void)update:(ccTime)dt {
    Player *p = [[GameController sharedController] player];
    [_scoreLabel  setString: [NSString stringWithFormat: @"%@", p.score]];
    [_currentLevelLabel setString: [NSString stringWithFormat:@"%d",  [p.currentLevel intValue] + 1]];
    
    int experienceLevel = [p.experienceLevel intValue];
    if (experienceLevel >= 10) {
        _experienceDisplayLevel0.isEnabled = YES;
    } else {
        _experienceDisplayLevel0.isEnabled = NO;
    }
    if (experienceLevel >= 100) {
        _experienceDisplayLevel1.isEnabled = YES;
    } else {
        _experienceDisplayLevel1.isEnabled = NO;
    }
    if (experienceLevel >= 200) {
        _experienceDisplayLevel2.isEnabled = YES;
    } else {
        _experienceDisplayLevel2.isEnabled = NO;
    }
    if (experienceLevel >= 300) {
        _experienceDisplayLevel3.isEnabled = YES;
    } else {
        _experienceDisplayLevel3.isEnabled = NO;
    }
    if (experienceLevel >= 400) {
        _experienceDisplayLevel4.isEnabled = YES;
    } else {
        _experienceDisplayLevel4.isEnabled = NO;
    }
    
    [self unscheduleUpdate];
}

@end
