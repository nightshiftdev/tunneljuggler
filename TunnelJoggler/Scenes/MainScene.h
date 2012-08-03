//
//  MainScene.h
//  StickyET
//
//  Created by pawel on 4/21/11.
//  Copyright 2011 __etcApps__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

@interface MainScene : CCLayer <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate> {
//	CCMenu *menuSoundOnOff_;
	CCParticleSystem *emitter;
    CCMenu *_playerPictureMenu;
}
@property (readwrite,retain) CCParticleSystem *emitter;
+(id) scene;
-(void)reloadGameData:(id)sender;
//-(void) toggleSoundOnOffBtn;
//-(CCMenuItem*) itemSoundOnOff;

@end
