//
//  HUD.m
//  TunnelJoggler
//
//  Created by pawel on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Game.h"
#import "HUD.h"

@implementation HUD

+(id) HUDWithGameNode:(Game*)game {
	return [[[self alloc] initWithGameNode:game] autorelease];
}

-(id) initWithGameNode:(Game*)game {
	if( (self=[super init])) {
		self.isTouchEnabled = YES;
		game_ = game;
        
		CGSize s = [[CCDirector sharedDirector] winSize];
		
//		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"buttons.plist"];
//		[[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"sprites.plist"];
		
		CCLayerColor *color = [CCLayerColor layerWithColor:ccc4(32,32,32,32) width:40 height:s.height];
		[color setPosition:ccp(s.width-40,0)];
		[self addChild:color z:0];
	}
	return self;
}

-(void) gameOver:(BOOL)didWin touchedFatalObject:(BOOL) fatalObjectTouched {
    
}

-(void) onUpdateScore:(int)newScore {
    
}


@end
