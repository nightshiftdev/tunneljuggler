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
#import "UIImage+WithScaleToSize.h"

@interface MainScene()
- (void)showImagePicker:(BOOL)hasCamera;
- (void) setUserPictureForNormalState: (CCSprite *) normalStateSprite selectedState: (CCSprite *) selectedStateSprite;
- (void) showLeaderboard;

@property (retain, nonatomic, readwrite) CCMenuItem *itemUserPicture;
@property (retain, nonatomic, readwrite) CCMenu *playerPictureMenu;
@end


@implementation MainScene

@synthesize emitter;
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
		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"buttons.plist"];
		
		CGSize s = [[CCDirector sharedDirector] winSize];
		CCSprite *background = [BackgroundUtils genBackground];
		background.position = ccp(s.width/2, s.height/2);
		[self addChild:background z:-10];
        
        CCMenuItem *itemUserPictureFrame = [SoundMenuItem itemFromNormalSpriteFrameName:@"player-picture-frame.png" selectedSpriteFrameName:@"player-picture-frame.png" target:nil selector:nil];
        itemUserPictureFrame.isEnabled = NO;
		CCMenu *menuUserPictureFrame = [CCMenu menuWithItems: itemUserPictureFrame, nil];
		menuUserPictureFrame.position = ccp(s.width/2 + 100, s.height/2);
		[self addChild:menuUserPictureFrame z:5];
        
        id scaleTo = [CCScaleTo actionWithDuration:0.5f scale:0.9f];
		id scaleBack = [CCScaleTo actionWithDuration:0.5f scale:1.0f];
        id rotateLeft = [CCRotateBy actionWithDuration:0.1f angle:5.0f];
        id rotateRight = [CCRotateBy actionWithDuration:0.2f angle:-10.0f];
        
		id seq = [CCSequence actions:scaleTo, scaleBack, rotateLeft, rotateRight, rotateLeft, nil];
        
		CCMenuItem *itemPlay = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-play-normal.png" selectedSpriteFrameName:@"btn-play-selected.png" target:self selector:@selector(playGame:)];
		CCMenu *menuPlay = [CCMenu menuWithItems: itemPlay, nil];
		menuPlay.position = ccp(s.width/8, s.height/2);
        [itemPlay runAction:[CCRepeatForever actionWithAction:seq]];
		[self addChild:menuPlay];
        
        Player *p = [[GameController sharedController] player];
        CCSprite *spriteFromImageNormal = nil;
        CCSprite *spriteFromImageSelected = nil;
        UIImage *playerPicture = p.picture;
        if (playerPicture != nil) {
            spriteFromImageNormal = [CCSprite spriteWithCGImage: playerPicture.CGImage key:nil];
            spriteFromImageSelected = [CCSprite spriteWithCGImage: playerPicture.CGImage key:nil];
        } else {
            spriteFromImageNormal = [CCSprite spriteWithSpriteFrameName: @"player-picture-default.png"];
            spriteFromImageSelected = [CCSprite spriteWithSpriteFrameName: @"player-picture-default.png"];
        }
        
        [self setUserPictureForNormalState: spriteFromImageNormal
                             selectedState: spriteFromImageSelected];
        
        
        // Score
		_scoreLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"H I G H  S C O R E:  %d", [p.score intValue]] fntFile:@"sticky.fnt"];
		[_scoreLabel.texture setAliasTexParameters];
		[self addChild:_scoreLabel z:1];
		[_scoreLabel setPosition:ccp(s.width/2 - 40, s.height/2)];
        _scoreLabel.rotation = 90;
        
        
        // Expirience
		_experienceLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"E X P E R I E N C E  L E V E L:  %d", [p.experienceLevel intValue]] fntFile:@"sticky.fnt"];
		[_experienceLabel.texture setAliasTexParameters];
		[self addChild:_experienceLabel z:1];
		[_experienceLabel setPosition:ccp(s.width/2 - 80, s.height/2)];
        _experienceLabel.rotation = 90;
        
        // Current level
		_currentLevelLabel = [CCLabelBMFont labelWithString:[NSString stringWithFormat:@"C U R R E N T  L E V E L:  %d", [p.currentLevel intValue]] fntFile:@"sticky.fnt"];
		[_currentLevelLabel.texture setAliasTexParameters];
		[self addChild:_currentLevelLabel z:1];
		[_currentLevelLabel setPosition:ccp(s.width/2 - 120, s.height/2)];
        _currentLevelLabel.rotation = 90;
        
        CCMenuItem *itemGameCenter = [SoundMenuItem itemFromNormalSpriteFrameName:@"hero-gamecenter.png" selectedSpriteFrameName:@"hero-gamecenter.png" target:self selector:@selector(highScoreGameCenter:)];
		CCMenu *menuGameCenter = [CCMenu menuWithItems: itemGameCenter, nil];
		menuGameCenter.position = ccp(s.width/2 - 40, s.height - 44);
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
	
	return self;
}

- (void)dealloc {
    self.playerPictureMenu = nil;
    self.itemUserPicture = nil;
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

-(void) playGame:(id)sender {
	[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.1f scene:[Game scene]]];
}

-(void)reloadGameData:(id)sender {
#ifdef DEBUG
    NSLog(@"MainScene reloadGameData called.");
#endif
    Player *p = [[GameController sharedController] player];
    CCSprite *spriteFromImageNormal = nil;
    CCSprite *spriteFromImageSelected = nil;
    UIImage *playerPicture = p.picture;
    if (playerPicture != nil) {
        spriteFromImageNormal = [CCSprite spriteWithCGImage: playerPicture.CGImage key:nil];
        spriteFromImageSelected = [CCSprite spriteWithCGImage: playerPicture.CGImage key:nil];
    } else {
        spriteFromImageNormal = [CCSprite spriteWithSpriteFrameName: @"player-picture-default.png"];
        spriteFromImageSelected = [CCSprite spriteWithSpriteFrameName: @"player-picture-default.png"];
    }
    
    [self setUserPictureForNormalState: spriteFromImageNormal
                         selectedState: spriteFromImageSelected];
    
    [_scoreLabel setString: [NSString stringWithFormat:@"H I G H  S C O R E:  %d", [p.score intValue]]];
    
    [_experienceLabel setString: [NSString stringWithFormat:@"E X P E R I E N C E  L E V E L:  %d", [p.experienceLevel intValue]]];
    
    [_currentLevelLabel setString: [NSString stringWithFormat:@"C U R R E N T  L E V E L:  %d", [p.currentLevel intValue]]];
}

-(void) changePicture:(id)sender {
    BOOL hasCamera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
    
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil
                                                    delegate:self
                                           cancelButtonTitle:nil
                                      destructiveButtonTitle:nil
                                           otherButtonTitles:nil];
    
    if (hasCamera) {
        [as addButtonWithTitle:@"Take Photo"];
    }
    
    [as addButtonWithTitle:@"Choose Existing Photo"];
    [as addButtonWithTitle:@"Use Default Image"];
    [as addButtonWithTitle:@"Cancel"];
    as.cancelButtonIndex = [as numberOfButtons] - 1;
    
    [as showInView:[[UIApplication sharedApplication] delegate].window];
    [as release];
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

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void) actionSheet:(UIActionSheet *)as clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (as.cancelButtonIndex == buttonIndex) {
        return;
    } else if (buttonIndex == 2) {
        CCSprite *spriteFromImageNormal = [CCSprite spriteWithSpriteFrameName: @"player-picture-default.png"];
        CCSprite *spriteFromImageSelected = [CCSprite spriteWithSpriteFrameName: @"player-picture-default.png"];
        [self setUserPictureForNormalState: spriteFromImageNormal
                             selectedState: spriteFromImageSelected];
        Player *p = [[GameController sharedController] player];
        p.picture = nil;
        [[GameController sharedController] setPlayer: p];
    } else  {
        NSString *title = [as buttonTitleAtIndex:buttonIndex];
        if ([title isEqualToString:@"Take Photo"]) {
            [self showImagePicker:true];
        }	
        else {
            [self showImagePicker:false];
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
    self.itemUserPicture = [SoundMenuItem itemFromNormalSprite: normalStateSprite
                                                selectedSprite: selectedStateSprite
                                                        target:self
                                                      selector: @selector(changePicture:)
                            ];
    self.playerPictureMenu = [CCMenu menuWithItems: self.itemUserPicture, nil];
    self.playerPictureMenu.position = ccp(s.width/2 + 100, s.height/2);
    self.playerPictureMenu.isTouchEnabled = YES;
    [itemUserPicture runAction:[CCRepeatForever actionWithAction:seq]];
    [self addChild:self.playerPictureMenu z:10];
}

- (void) showImagePicker:(BOOL)hasCamera {
    self.playerPictureMenu.isTouchEnabled = NO;
    UIImagePickerController *picker	= [[UIImagePickerController alloc]init];
	picker.delegate = self;
    if (hasCamera) {
		picker.sourceType = UIImagePickerControllerSourceTypeCamera;
	}
	picker.wantsFullScreenLayout = YES;
    picker.view.transform = CGAffineTransformMakeRotation(-M_PI/2);
    picker.view.frame = CGRectMake(0.0, 0.0, 480.0, 320.0);
	[[[UIApplication sharedApplication] delegate].window.rootViewController presentModalViewController:picker animated:YES];
    
	[[[CCDirector sharedDirector] openGLView] addSubview:picker.view];
    
	// Pause the Directore to speed up image picker (maybe it's better to put it before adding the view??)
	[[CCDirector sharedDirector] pause];
	[[CCDirector sharedDirector] stopAnimation];
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

#pragma mark -
#pragma mark UIImagePickerControllerDelegate protocol methods

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    float userPictureSize =  128.0 * [CCDirector sharedDirector].contentScaleFactor;
    UIImage *scaledImage = [image scaleToSize: CGSizeMake(userPictureSize, userPictureSize)];
    UIImage *imageToSave = [UIImage makeRoundCornerImage: scaledImage :25 : 25];
    
    Player *p = [[GameController sharedController] player];
    p.picture = imageToSave;
    [[GameController sharedController] setPlayer: p];
    
    CCSprite *spriteFromImageNormal = [CCSprite spriteWithCGImage: imageToSave.CGImage key:nil];
    CCSprite *spriteFromImageSelected = [CCSprite spriteWithCGImage: imageToSave.CGImage key:nil];
    
    [self setUserPictureForNormalState: spriteFromImageNormal
                         selectedState: spriteFromImageSelected];
    
	[picker dismissModalViewControllerAnimated:YES];
	[picker.view removeFromSuperview];
	[picker	release];
    
	[[CCDirector sharedDirector] startAnimation];
	[[CCDirector sharedDirector] resume];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    self.playerPictureMenu.isTouchEnabled = YES;
	[picker dismissModalViewControllerAnimated:YES];
	[picker.view removeFromSuperview];
	[picker	release];
    [[CCDirector sharedDirector] startAnimation];
	[[CCDirector sharedDirector] resume];
}

@end
