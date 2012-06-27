//
//  Obstacle.h
//  TunnelJoggler
//
//  Created by pawel on 4/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Box2D.h"
#import "CCSprite.h"

@class Game;

@interface Obstacle : CCSprite {
    b2World *world_;
    b2Body *body_;
    CCParticleSystem *emitter;
}

- (id)initWithWorld:(b2World *)world position: (CGPoint) position game: (Game *) g;
- (void)update:(ccTime)dt;
- (b2Body *) body;
- (void)explode;

@property (nonatomic, readwrite, retain) CCParticleSystem *emitter;
@property (nonatomic, retain) Game *game;

@end
