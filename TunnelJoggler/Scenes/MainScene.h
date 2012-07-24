//
//  MainScene.h
//  StickyET
//
//  Created by pawel on 4/21/11.
//  Copyright 2011 __etcApps__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface MainScene : CCLayer {
//	CCMenu *menuSoundOnOff_;
	CCParticleSystem *emitter;
}
@property (readwrite,retain) CCParticleSystem *emitter;
+(id) scene;
//-(void) toggleSoundOnOffBtn;
//-(CCMenuItem*) itemSoundOnOff;

@end
