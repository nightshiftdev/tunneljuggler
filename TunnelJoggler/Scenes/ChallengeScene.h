//
//  ChallengeScene.h
//  TunnelJuggler
//
//  Created by pawel on 8/26/12.
//  Copyright 2012 __etcApps__. All rights reserved.
//

#import "cocos2d.h"

@class Level;

@interface ChallengeScene : CCLayer {
    Level* _currentLevel;
}
+(id) scene;
@end
