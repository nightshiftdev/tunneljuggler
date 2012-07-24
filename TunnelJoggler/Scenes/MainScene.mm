//
//  MainScene.mm
//  StickyET
//
//  Created by pawel on 4/21/11.
//  Copyright 2011 __etcApps__. All rights reserved.
//


#import "MainScene.h"
#import "SoundMenuItem.h"
#import "Game.h"
#import "SimpleAudioEngine.h"

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
		CCSprite *background = [CCSprite spriteWithFile:@"main-scene-background.png"];
		background.position = ccp(s.width/2, s.height/2);
		[self addChild:background z:-10];
		
		id scaleTo = [CCScaleTo actionWithDuration:0.5f scale:0.9f];
		id scaleBack = [CCScaleTo actionWithDuration:0.5f scale:1];
		id seq = [CCSequence actions:scaleTo, scaleBack, nil];
        
		CCMenuItem *itemPlay = [SoundMenuItem itemFromNormalSpriteFrameName:@"btn-play-normal.png" selectedSpriteFrameName:@"btn-play-selected.png" target:self selector:@selector(playGame:)];
		CCMenu *menuPlay = [CCMenu menuWithItems: itemPlay, nil];
		menuPlay.position = ccp(s.width/2, s.height/2);
        [itemPlay runAction:[CCRepeatForever actionWithAction:seq]];
		[self addChild:menuPlay];
		
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

-(void) onEnter {
	[super onEnter];
	self.emitter = [CCParticleGalaxy node];
	[self addChild: emitter z:-5];
	if(CGPointEqualToPoint( emitter.sourcePosition, CGPointZero)) {
        CGSize s = [[CCDirector sharedDirector] winSize];
		emitter.position = ccp(s.width/2, s.height/2);
    }
}

-(void) playGame:(id)sender {
	[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.1f scene:[Game scene]]];
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

@end
