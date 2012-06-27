//
//  Obstacle.m
//  TunnelJoggler
//
//  Created by pawel on 4/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Game.h"
#import "BallBullet.h"

@implementation BallBullet

@synthesize emitter;
@synthesize game;

- (void)createBodyAtPosition: (CGPoint) position {
    // Create obstacle body
    b2BodyDef ballBulletBodyDef;
    ballBulletBodyDef.type = b2_dynamicBody;
    ballBulletBodyDef.position.Set(position.x/PTM_RATIO, position.y/PTM_RATIO);
    self.tag = 1;
    ballBulletBodyDef.userData = self;
    body_ = world_->CreateBody(&ballBulletBodyDef);
    
    // Create obstacle shape
    b2CircleShape ballBulletShape;
    ballBulletShape.m_radius = self.contentSize.width/PTM_RATIO/2;
    
    // Create shape definition and add to body
    b2FixtureDef ballBulletShapeDef;
    ballBulletShapeDef.shape = &ballBulletShape;
    ballBulletShapeDef.density = 0.5f;
    ballBulletShapeDef.friction = 0.1f;
    ballBulletShapeDef.restitution = 1.0f;
    body_->CreateFixture(&ballBulletShapeDef);
//  CCParticleExplosion CCParticleSun CCParticleGalaxy CCParticleSmoke CCParticleRain
//  CCParticleFlower CCParticleFire CCParticleSpiral CCParticleSnow
    self.emitter = [CCParticleFlower node];
	[self.game addChild: emitter z:1];
    self.emitter.scale = 0.1;
    self.emitter.positionType = kCCPositionTypeRelative;
}

- (id)initWithWorld:(b2World *)world position: (CGPoint) position game: (Game *) g {
    if ((self = [super initWithSpriteFrameName:@"Ball.png"])) {
        self.game = g;
        world_ = world;
        [self createBodyAtPosition:position];
    }
    return self;
}

- (void)update:(ccTime)dt {
    self.position = ccp(body_->GetPosition().x*PTM_RATIO, body_->GetPosition().y*PTM_RATIO);
    float x = self.position.x + self.game.terrain.position.x;
    self.emitter.position = CGPointMake(x, self.position.y);
}

- (b2Body *) body {
    return body_;
}

- (void)resetEmitter {
    [self.game removeChild:self.emitter cleanup:YES];
}

- (void) dealloc {
	[emitter release];
    [game release];
	[super dealloc];	
}

@end
