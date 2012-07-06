//
//  BallBullet.h
//  TunnelJoggler
//
//  Created by pawel on 4/15/12.
//  Copyright (c) 2012 Pawel Kijowski. All rights reserved.
//

#import "Box2D.h"
#import "CCSprite.h"

@class Game;

@interface BallBullet : CCSprite {
    b2World *world_;
    b2Body *body_;
    CCParticleSystem *emitter;
}

- (id)initWithWorld:(b2World *)world position: (CGPoint) position game: (Game *) g;
- (void)update:(ccTime)dt;
- (void)resetEmitter;
- (b2Body *) body;
@property (nonatomic, readwrite, retain) CCParticleSystem *emitter;
@property (nonatomic, retain) Game *game;

@end
