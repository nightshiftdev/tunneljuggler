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
- (CCSprite *)genBackground;
- (void)showImagePicker:(BOOL)hasCamera;
@end


@implementation MainScene

@synthesize emitter;

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
		CCSprite *background = [self genBackground];
		background.position = ccp(s.width/2, s.height/2);
		[self addChild:background z:-10];

        CCMenuItem *itemUserPictureFrame = [SoundMenuItem itemFromNormalSpriteFrameName:@"player-picture-frame.png" selectedSpriteFrameName:@"player-picture-frame.png" target:nil selector:nil];
        itemUserPictureFrame.isEnabled = NO;
		CCMenu *menuUserPictureFrame = [CCMenu menuWithItems: itemUserPictureFrame, nil];
		menuUserPictureFrame.position = ccp(s.width/2 + 50, s.height/2);
		[self addChild:menuUserPictureFrame z:5];
        
        id scaleTo = [CCScaleTo actionWithDuration:0.5f scale:0.9f];
		id scaleBack = [CCScaleTo actionWithDuration:0.5f scale:1.0f];
        id rotateLeft = [CCRotateBy actionWithDuration:0.2f angle:-5.0f];
        id rotateRight = [CCRotateBy actionWithDuration:0.4f angle:10.0f];
        
        id seq = [CCSequence actions:rotateLeft, rotateRight, rotateLeft, nil];
        
        CCMenuItem *itemUserPicture = [SoundMenuItem itemFromNormalSpriteFrameName:@"player-picture-default.png" selectedSpriteFrameName:@"player-picture-default.png" target:self selector:@selector(changePicture:)];
		_playerPictureMenu = [CCMenu menuWithItems: itemUserPicture, nil];
        _playerPictureMenu.position = ccp(s.width/2 + 50, s.height/2);
        [itemUserPicture runAction:[CCRepeatForever actionWithAction:seq]];
		[self addChild:_playerPictureMenu z:10];

        rotateLeft = [CCRotateBy actionWithDuration:0.1f angle:5.0f];
        rotateRight = [CCRotateBy actionWithDuration:0.2f angle:-10.0f];
        
		seq = [CCSequence actions:scaleTo, scaleBack, rotateLeft, rotateRight, rotateLeft, nil];
        
		CCMenuItem *itemPlay = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-play-normal.png" selectedSpriteFrameName:@"btn-play-selected.png" target:self selector:@selector(playGame:)];
		CCMenu *menuPlay = [CCMenu menuWithItems: itemPlay, nil];
		menuPlay.position = ccp(s.width/8, s.height/2);
        [itemPlay runAction:[CCRepeatForever actionWithAction:seq]];
		[self addChild:menuPlay];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadGameData:)
                                                     name:NSPersistentStoreCoordinatorStoresDidChangeNotification
                                                   object:[GameController sharedController].psc];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reloadGameData:)
                                                     name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                   object:[GameController sharedController].psc];
        
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background-music-aac.caf"];
		
//		CCMenuItem *itemCredits = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-credits-normal.png" selectedSpriteFrameName:@"btn-credits-selected.png" target:self selector:@selector(showCredits:)];
//		CCMenu *menuCredits = [CCMenu menuWithItems: itemCredits, nil];
//		menuCredits.position = ccp(350, 200);
//		[self addChild:menuCredits];
		
		
		// how to play button
//		SoundMenuItem *howToPlayButton = [SoundMenuItem itemFromNormalSpriteFrameName:@"how-to-play-normal.png" selectedSpriteFrameName:@"how-to-play-selected.png" target:self selector:@selector(howToPlayCallback:)];	
//		howToPlayButton.position = ccp(s.width - 100,s.height - 5);
//		howToPlayButton.anchorPoint = ccp(0,1);
		
//		CCMenu *menu = [CCMenu menuWithItems:howToPlayButton, nil];
//		menu.position = ccp(0,0);
//		[self addChild: menu z:0];
		

//		// facebook
//		SoundMenuItem *facebookButton = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-facebook.png" selectedSpriteFrameName:@"btn-facebook.png" target:self selector:@selector(facebookCallback:)];	
//		facebookButton.position = ccp(5, 55);
//		facebookButton.anchorPoint = ccp(0,1);
//		[facebookButton runAction:[CCRepeatForever actionWithAction:seq]];
//		
//		menu = [CCMenu menuWithItems:facebookButton, nil];
//		menu.position = ccp(0,0);
//		[self addChild: menu z:0];
//		
//		// twitter
//		SoundMenuItem *twitterButton = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-twitter.png" selectedSpriteFrameName:@"btn-twitter.png" target:self selector:@selector(twitterCallback:)];	
//		twitterButton.position = ccp(60, 55);
//		twitterButton.anchorPoint = ccp(0,1);
//		[twitterButton runAction:[CCRepeatForever actionWithAction:seq]];
//		
//		menu = [CCMenu menuWithItems:twitterButton, nil];
//		menu.position = ccp(0,0);
//		[self addChild: menu z:0];
		
//		[self toggleSoundOnOffBtn];
		
//		[[ProgressManager getOrInitProgress] playMainTheme];
	}
	
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [super dealloc];
}

-(void) onEnter {
	[super onEnter];
//	self.emitter = [CCParticleGalaxy node];
//	[self addChild: emitter z:-5];
//	if(CGPointEqualToPoint( emitter.sourcePosition, CGPointZero)) {
//        CGSize s = [[CCDirector sharedDirector] winSize];
//		emitter.position = ccp(s.width/2, s.height/2);
//    }
}

-(void) playGame:(id)sender {
	[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.1f scene:[Game scene]]];
}

-(void) changePicture:(id)sender {
    [self showImagePicker: NO];
//    BOOL hasCamera = [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
//    
//    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:nil
//                                                    delegate:self
//                                           cancelButtonTitle:nil
//                                      destructiveButtonTitle:nil
//                                           otherButtonTitles:nil];
//    
//    if (hasCamera) {
//        [as addButtonWithTitle:@"Take Photo"];
//    }
//    
//    [as addButtonWithTitle:@"Choose Existing Photo"];
//    [as addButtonWithTitle:@"Cancel"];
//    as.cancelButtonIndex = [as numberOfButtons] - 1;
//    
//    [as showInView:[[UIApplication sharedApplication] delegate].window];
    
    //[self pickPhoto: UIImagePickerControllerSourceTypePhotoLibrary];
}

-(void)reloadGameData:(id)sender {
    NSLog(@"reloadGameData called.");
}

//-(void) soundOnOff:(id)sender {
//	BOOL mute = [[SimpleAudioEngine sharedEngine] mute];
//	[[SimpleAudioEngine sharedEngine] setMute:!mute];
//	[self toggleSoundOnOffBtn];
//}

//-(void) toggleSoundOnOffBtn {
//	if (menuSoundOnOff_ != nil) {
//		[self removeChild:menuSoundOnOff_ cleanup:NO];
//	} 
//	menuSoundOnOff_ = [CCMenu menuWithItems: [self itemSoundOnOff], nil];
//	menuSoundOnOff_.position = ccp(90, 125);
//	[self addChild:menuSoundOnOff_];
//}

//-(CCMenuItem*) itemSoundOnOff {
//	NSString *soundBtnNameNormal = @"btn-sound-off-normal.png";
//	NSString *soundBtnNameSelected = @"btn-sound-off-selected.png";
//	BOOL mute = [[SimpleAudioEngine sharedEngine] mute];
//	if (mute) {
//		soundBtnNameNormal = @"btn-sound-on-normal.png";
//		soundBtnNameSelected = @"btn-sound-on-selected.png";
//	}
//	
//	return [SoundMenuItem itemFromNormalSpriteFrameName:soundBtnNameNormal selectedSpriteFrameName:soundBtnNameSelected target:self selector:@selector(soundOnOff:)];
//}

//-(void) facebookCallback:(id)sender {
//	NSString *stringURL = @"http://www.facebook.com/people/@/100003382218124";
//	NSURL *url = [NSURL URLWithString:stringURL];
//	[[UIApplication sharedApplication] openURL:url];
//}

//-(void) twitterCallback:(id)sender {
//	NSString *stringURL = @"http://twitter.com/etcapps";
//	NSURL *url = [NSURL URLWithString:stringURL];
//	[[UIApplication sharedApplication] openURL:url];
//}

- (CCSprite *)genBackground {
    ccColor4F color1 = [BackgroundUtils randomBrightColor];
    ccColor4F color2 = [BackgroundUtils randomBrightColor];
    
    if (SOFTLAYER) {
        ccColor4B blackColor = 
        ccc4(1,
             1, 
             1, 
             255);
        color1 = ccc4FFromccc4B(blackColor);
        ccColor4B redColor = 
        ccc4(255,
             0, 
             0, 
             255);
        color2 = ccc4FFromccc4B(redColor);
    }
    
    float screenFactor = [CCDirector sharedDirector].contentScaleFactor;
    CCSprite *stripes = [BackgroundUtils stripedSpriteWithColor1:color1 color2:color2 textureSize:512 stripes: 6 * screenFactor];
    ccTexParams tp2 = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_CLAMP_TO_EDGE};
    [stripes.texture setTexParameters:&tp2];
    return stripes;
}

#pragma mark -
#pragma mark UIActionSheetDelegate

- (void) actionSheet:(UIActionSheet *)as clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (as.cancelButtonIndex == buttonIndex) {
        return;
    }
   	
    NSString *title = [as buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:@"Take Photo"]) {
        [self showImagePicker:true];
    }	
    else {
		[self showImagePicker:false];
    }
}

- (void) showImagePicker:(BOOL)hasCamera {
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

#pragma mark -
#pragma mark UIImagePickerControllerDelegate protocol methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    [self removeChild: _playerPictureMenu cleanup: YES];
	UIImage *newImage = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    UIImage *scaledImage = [newImage scaleToSize: CGSizeMake(100, 100)];
    scaledImage = [UIImage makeRoundCornerImage: scaledImage :10 : 10];
    CCSprite *spriteFromImageNormal = [CCSprite spriteWithCGImage: scaledImage.CGImage key:nil];
    CCSprite *spriteFromImageSelected = [CCSprite spriteWithCGImage: scaledImage.CGImage key:nil];
    
    id rotateLeft = [CCRotateBy actionWithDuration:0.2f angle:-5.0f];
    id rotateRight = [CCRotateBy actionWithDuration:0.4f angle:10.0f];
    
    id seq = [CCSequence actions:rotateLeft, rotateRight, rotateLeft, nil];
    
    CGSize s = [[CCDirector sharedDirector] winSize];
    CCMenuItem *itemUserPicture = [SoundMenuItem itemFromNormalSprite: spriteFromImageNormal selectedSprite: spriteFromImageSelected target:self selector:@selector(changePicture:)];
    _playerPictureMenu = [CCMenu menuWithItems: itemUserPicture, nil];
    _playerPictureMenu.position = ccp(s.width/2 + 50, s.height/2);
    [itemUserPicture runAction:[CCRepeatForever actionWithAction:seq]];
    [self addChild:_playerPictureMenu z:10];
    
	[picker dismissModalViewControllerAnimated:YES];
	[picker.view removeFromSuperview];
	[picker	release];
    
	[[CCDirector sharedDirector] startAnimation];
	[[CCDirector sharedDirector] resume];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	[picker dismissModalViewControllerAnimated:YES];
	[picker.view removeFromSuperview];
	[picker	release];
    [[CCDirector sharedDirector] startAnimation];
	[[CCDirector sharedDirector] resume];
}

@end
