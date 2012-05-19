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
}

- (id)initWithWorld:(b2World *)world position: (CGPoint) position {
    if ((self = [super initWithSpriteFrameName:@"Ball.png"])) {
        world_ = world;
        [self createBodyAtPosition:position];
    }
    return self;
}

- (void)update:(ccTime)dt {
    self.position = ccp(body_->GetPosition().x*PTM_RATIO, body_->GetPosition().y*PTM_RATIO);
}

- (b2Body *) body {
    return body_;
}

@end
