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

@interface MainScene : CCLayer <UIImagePickerControllerDelegate,
                                UINavigationControllerDelegate,
                                UIActionSheetDelegate,
                                GKLeaderboardViewControllerDelegate>
{
	CCParticleSystem *emitter;
    CCLabelBMFont *_scoreLabel;
    CCLabelBMFont *_experienceLabel;
    CCLabelBMFont *_currentLevelLabel;
}
@property (readwrite,retain) CCParticleSystem *emitter;
+(id) scene;
-(void)reloadGameData:(id)sender;

@end
