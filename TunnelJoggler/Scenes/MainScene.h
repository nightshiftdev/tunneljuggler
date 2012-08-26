//
//  MainScene.h
//  StickyET
//
//  Created by pawel on 4/21/11.
//  Copyright 2011 __etcApps__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "cocos2d.h"

@interface MainScene : CCLayer <GKLeaderboardViewControllerDelegate>
{
    CCLabelBMFont *_scoreLabel;
    CCLabelBMFont *_experienceLabel;
    CCLabelBMFont *_currentLevelLabel;
}
+(id) scene;
@end
