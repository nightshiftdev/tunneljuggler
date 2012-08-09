//
//  MainScene.h
//  StickyET
//
//  Created by pawel on 4/21/11.
//  Copyright 2011 __etcApps__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "GameCenterManager.h"
#import <GameKit/GameKit.h>

@interface MainScene : CCLayer <UIImagePickerControllerDelegate,
                                UINavigationControllerDelegate,
                                UIActionSheetDelegate,
                                GKLeaderboardViewControllerDelegate,
                                GameCenterManagerDelegate>
{
    //	CCMenu *menuSoundOnOff_;
    GameCenterManager *gameCenterManager;
	CCParticleSystem *emitter;
    CCLabelBMFont *_scoreLabel;
    CCLabelBMFont *_experienceLabel;
    CCLabelBMFont *_currentLevelLabel;
}
@property (nonatomic, retain) GameCenterManager *gameCenterManager;
@property (readwrite,retain) CCParticleSystem *emitter;
+(id) scene;
-(void)reloadGameData:(id)sender;
//-(void) toggleSoundOnOffBtn;
//-(CCMenuItem*) itemSoundOnOff;

@end
