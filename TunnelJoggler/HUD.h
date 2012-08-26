//
//  HUD.h
//  TunnelJoggler
//
//  Created by pawel on 5/18/12.
//  Copyright (c) 2012 __etcApps__. All rights reserved.
//

#import "cocos2d.h"

@class Game;
@class Level;

@interface HUD : CCLayer {
    Game *game_;
    CCLabelBMFont *scoreLabel_;
    CCLabelBMFont *_timeLabel;
    CCLabelBMFont *_scoreChallengeLabel;
    CCMenu *menu_;
    int _minutes;
    int _seconds;
    Level* _currentLevel;
}

@property (assign, nonatomic, readonly) BOOL isShowingHowToPlay;
@property (assign, nonatomic, readonly) BOOL isShowingTimeChallenge;

+(id) HUDWithGameNode:(Game*)game;
-(id) initWithGameNode:(Game*)game;
-(void) gameOver:(BOOL)didWin touchedFatalObject:(BOOL) fatalObjectTouched;
-(void) onUpdateScore:(int)addScore;
-(void) pause;
-(void) showHowToPlay;
-(void) dismissHowToPlay:(id)sender;
-(void) onUpdateCountDownTimer;

@end
