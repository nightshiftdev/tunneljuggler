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
    CCLabelBMFont *score_;
    CCMenu *menu_;
}

+(id) HUDWithGameNode:(Game*)game;
-(id) initWithGameNode:(Game*)game;
-(void) gameOver:(BOOL)didWin touchedFatalObject:(BOOL) fatalObjectTouched;
-(void) onUpdateScore:(int)newScore;
-(void) pause;

@end
