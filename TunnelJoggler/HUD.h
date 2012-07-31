//
//  HUD.h
//  TunnelJoggler
//
//  Created by pawel on 5/18/12.
//  Copyright (c) 2012 __etcApps__. All rights reserved.
//

#import "cocos2d.h"

@class Game;

@interface HUD : CCLayer {
    Game *game_;
    CCLabelBMFont *scoreLabel_;
    CCMenu *menu_;
}

@property (assign, nonatomic, readonly) BOOL isShowingHowToPlay;

+(id) HUDWithGameNode:(Game*)game;
-(id) initWithGameNode:(Game*)game;
-(void) gameOver:(BOOL)didWin touchedFatalObject:(BOOL) fatalObjectTouched;
-(void) onUpdateScore:(int)addScore;
-(void) pause;
-(void) showHowToPlay;
-(void) dismissHowToPlay:(id)sender;

@end
