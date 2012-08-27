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
            CCMenu *menuFrame = [CCMenu menuWithItems: itemFrame, nil];
            menuFrame.position = ccp(s.width/2, s.height/2);
            [self addChild:menuFrame z:0];
            
            //game title
            CCMenuItem *itemTitle = [SoundMenuItem itemFromNormalSpriteFrameName:@"main-title.png" selectedSpriteFrameName:@"main-title.png" target:nil selector:nil];
            itemTitle.isEnabled = NO;
            CCMenu *menuTitle = [CCMenu menuWithItems: itemTitle, nil];
            menuTitle.position = ccp(s.width/1.12, s.height/2);
            [self addChild:menuTitle z:2];
            
            
            // clown frame
            CCMenuItem *itemUserPictureFrame = [SoundMenuItem itemFromNormalSpriteFrameName:@"picture-frame.png" selectedSpriteFrameName:@"picture-frame.png" target:nil selector:nil];
            itemUserPictureFrame.isEnabled = NO;
            CCMenu *menuUserPictureFrame = [CCMenu menuWithItems: itemUserPictureFrame, nil];
            menuUserPictureFrame.position = ccp(s.width/1.35, s.height/2);
            [self addChild:menuUserPictureFrame z:1];
            
            id scaleTo = [CCScaleTo actionWithDuration:0.5f scale:0.9f];
            id scaleBack = [CCScaleTo actionWithDuration:0.5f scale:1.0f];
            id rotateLeft = [CCRotateBy actionWithDuration:0.1f angle:5.0f];
            id rotateRight = [CCRotateBy actionWithDuration:0.2f angle:-10.0f];
            
            id seq = [CCSequence actions:scaleTo, scaleBack, rotateLeft, rotateRight, rotateLeft, nil];
            
            //Play button
            CCMenuItem *itemPlay = [SoundMenuItem itemFromNormalSpriteFrameName:@"start-game-off.png" selectedSpriteFrameName:@"start-game-on.png" target:self selector:@selector(playGame:)];
            CCMenu *menuPlay = [CCMenu menuWithItems: itemPlay, nil];
            menuPlay.position = ccp(s.width/3, s.height/2);
            [itemPlay runAction:[CCRepeatForever actionWithAction:seq]];
            [self addChild:menuPlay];
            
            //Level ribbon
            CCMenuItem *itemLevelRibbon = [SoundMenuItem itemFromNormalSpriteFrameName:@"level-indicator.png" selectedSpriteFrameName:@"level-indicator.png" target:nil selector:nil];
            itemLevelRibbon.isEnabled = NO;
            CCMenu *menuLevelRibbon = [CCMenu menuWithItems: itemLevelRibbon, nil];
            menuLevelRibbon.position = ccp(s.width/2.5, s.height/3.5);
            [self addChild:menuLevelRibbon z:4];
            
            //Clown face
            CCSprite *spriteFromImageNormal = [CCSprite spriteWithSpriteFrameName: @"clown-face-happy.png"];
            CCSprite *spriteFromImageSelected = [CCSprite spriteWithSpriteFrameName: @"clown-face-happy.png"];
            [self setUserPictureForNormalState: spriteFromImageNormal
                                 selectedState: spriteFromImageSelected];
            
            //Score ribbon
            CCMenuItem *itemScoreRibbon = [SoundMenuItem itemFromNormalSpriteFrameName:@"score-frame.png" selectedSpriteFrameName:@"score-frame.png" target:nil selector:nil];
            itemScoreRibbon.isEnabled = NO;
            CCMenu *menuScoreRibbon = [CCMenu menuWithItems: itemScoreRibbon, nil];
            menuScoreRibbon.position = ccp(s.width/1.70, s.height/2);
            [self addChild:menuScoreRibbon z:4];
            
            // Score
            float fontSize = 28.0;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                fontSize = 56.0;
            }
            _scoreLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", [p.score intValue]] fontName:@"BosoxRevised.ttf" fontSize:fontSize];
            _scoreLabel.color = ccc3(204, 0, 0);
            [self addChild:_scoreLabel z:5];
            [_scoreLabel setPosition:ccp(s.width/1.65, s.height/2)];
            _scoreLabel.rotation = 90;
            
            // Expirience
            _experienceLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"E X P E R I E N C E  L E V E L:  %d", [p.experienceLevel intValue]] fontName:@"BosoxRevised.ttf" fontSize:28.0];
            _experienceLabel.color = ccc3(204, 0, 0);
            [self addChild:_experienceLabel z:1];
            [_experienceLabel setPosition:ccp(s.width/2 - 80, s.height/2)];
            _experienceLabel.rotation = 90;
            _experienceLabel.visible = NO;
            
            // Current level
            fontSize = 26.0;
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                fontSize = 52.0;
            }
            _currentLevelLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", [p.currentLevel intValue] + 1] fontName:@"BosoxRevised.ttf" fontSize:fontSize];
            _currentLevelLabel.color = ccc3(204, 0, 0);
            [self addChild:_currentLevelLabel z:5];
            [_currentLevelLabel setPosition:ccp(s.width/2.35, s.height/3.5)];
            _currentLevelLabel.rotation = 90;
            
            //Game center
            CCMenuItem *itemGameCenter = [SoundMenuItem itemFromNormalSpriteFrameName:@"game-center-off.png" selectedSpriteFrameName:@"game-center-on.png" target:self selector:@selector(highScoreGameCenter:)];
            CCMenu *menuGameCenter = [CCMenu menuWithItems: itemGameCenter, nil];
            menuGameCenter.position = ccp(s.width/9, s.height/2);
            id scaleGameCenterButtonTo = [CCScaleTo actionWithDuration:0.5f scale:0.9f];
            id scaleGameCenterButtonBack = [CCScaleTo actionWithDuration:0.5f scale:1.0f];
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

- (void)dealloc {
    self.playerPictureMenu = nil;
    self.itemUserPicture = nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

-(void) playGame:(id)sender {
    [[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.1f scene:[ChallengeScene scene]]];
}

-(void)reloadGameData:(id)sender {
#ifdef DEBUG
    NSLog(@"MainScene reloadGameData called.");
#endif
    Player *p = [[GameController sharedController] player];    
    [_scoreLabel setString: [NSString stringWithFormat:@"%d", [p.score intValue]]];
    
    [_experienceLabel setString: [NSString stringWithFormat:@"E X P E R I E N C E  L E V E L:  %d", [p.experienceLevel intValue]]];
    
    [_currentLevelLabel setString: [NSString stringWithFormat:@"%d", [p.currentLevel intValue]]];
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
    
    id rotateLeft = [CCRotateBy actionWithDuration:0.2f angle:-5.0f];
    id rotateRight = [CCRotateBy actionWithDuration:0.4f angle:10.0f];
    
    id seq = [CCSequence actions:rotateLeft, rotateRight, rotateLeft, nil];
    
    CGSize s = [[CCDirector sharedDirector] winSize];
    self.itemUserPicture = [SoundMenuItem itemFromNormalSprite:normalStateSprite
                                                selectedSprite:selectedStateSprite
                                                        target:self
                                                      selector:nil
                            ];
    self.itemUserPicture.isEnabled = NO;
    self.playerPictureMenu = [CCMenu menuWithItems: self.itemUserPicture, nil];
    self.playerPictureMenu.position = ccp(s.width/1.4, s.height/2);
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

@end
