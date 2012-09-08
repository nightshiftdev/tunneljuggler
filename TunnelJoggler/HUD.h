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
    CCLabelTTF *scoreLabel_;
    CCLabelTTF *_timeLabel;
    CCLabelTTF *_scoreChallengeLabel;
    CCLabelTTF *_scoreToPassChallengeLabel;
    CCLabelTTF *_lengthChallengeLabel;
    CCMenu *menu_;
    int _minutes;
    int _seconds;
    Level* _currentLevel;
    CCLayerColor *_pauseBackgroundColor;
    CCSprite *_happyClown;
    CCSprite *_sadClown;
    float _lastOffset;
    float _labelPosFactor;
}

@property (assign, nonatomic, readonly) BOOL isShowingHowToPlay;
@property (nonatomic, assign) float lengthRemainingToPassLevel;

+(id) HUDWithGameNode:(Game*)game;
-(id) initWithGameNode:(Game*)game;
-(void) gameOver:(BOOL)didWin touchedFatalObject:(BOOL) fatalObjectTouched;
-(void) onUpdateScore:(int)addScore;
-(void) pause;
-(void) showHowToPlay;
-(void) dismissHowToPlay:(id)sender;
-(void) onUpdateCountDownTimer;
-(void) onUpdateLengthCounter: (float) offset;
-(void)onLevelLenghtEnd;

@end
