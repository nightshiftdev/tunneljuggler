//
//  SplashScene.h
//  TunnelJuggler
//
//  Created by pawel on 4/21/11.
//  Copyright 2011 __etcApps__. All rights reserved.
//

#import "cocos2d.h"

@interface SplashScene : CCLayer {
    CCSprite *_preloader;
    CCAction *_jugglingAction;
}
+(id) scene;
@property (nonatomic, retain) CCSprite *preloader;
@property (nonatomic, retain) CCAction *jugglingAction;
@end
