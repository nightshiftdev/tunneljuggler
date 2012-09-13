//
//  Obstacle.h
//  TunnelJoggler
//
//  Created by pawel on 4/15/12.
//  Copyright (c) 2012 Pawel Kijowski. All rights reserved.
//

#import "Box2D.h"
#import "CCSprite.h"

@class Game;

@interface Obstacle : CCSprite {
    b2World *world_;
    b2Body *body_;
    CCParticleSystem *emitter;
    float _currentChangeDirectionTimeIterval;
}

- (id)initWithWorld:(b2World *)world position: (CGPoint) position game: (Game *) g;
- (void)update:(ccTime)dt;
- (b2Body *) body;
- (void)explode;

@property (nonatomic, readwrite, retain) CCParticleSystem *emitter;
@property (nonatomic, assign) Game *game;
@property (nonatomic, readwrite, assign) BOOL isMoving;
@property (nonatomic, readwrite, assign) float horizontalForce;
@property (nonatomic, readwrite, assign) float changeDirectionTimeIterval;

@end
