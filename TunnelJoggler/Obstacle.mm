//
//  Obstacle.m
//  TunnelJoggler
//
//  Created by pawel on 4/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Game.h"
#import "Obstacle.h"

@implementation Obstacle

- (void)createBodyAtPosition: (CGPoint) position {    
    // Create obstacle body
    b2BodyDef paddleBodyDef;
    paddleBodyDef.type = b2_kinematicBody;
    paddleBodyDef.position.Set(position.x/PTM_RATIO, position.y/PTM_RATIO);
    self.tag = 2;
    paddleBodyDef.userData = self;
    _body = _world->CreateBody(&paddleBodyDef);
    
    // Create obstacle shape
    b2PolygonShape paddleShape;
    paddleShape.SetAsBox(self.contentSize.width/PTM_RATIO/2, 
                         self.contentSize.height/PTM_RATIO/2);
    
    // Create shape definition and add to body
    b2FixtureDef paddleShapeDef;
    paddleShapeDef.shape = &paddleShape;
    paddleShapeDef.density = 0.0f;
    paddleShapeDef.friction = 0.1f;
    paddleShapeDef.restitution = 0.1f;
    _body->CreateFixture(&paddleShapeDef);
}

- (id)initWithWorld:(b2World *)world position: (CGPoint) position {
    if ((self = [super initWithSpriteFrameName:@"Block.png"])) {
        _world = world;
        [self createBodyAtPosition:position];
    }
    return self;
}

- (void)update:(ccTime)dt {
    static float offset = 0;
    offset += 1;
    
    _body->SetLinearVelocity(b2Vec2(0, 0));
    self.position = ccp(_body->GetPosition().x*PTM_RATIO, _body->GetPosition().y*PTM_RATIO);
}

- (b2Body *) body {
    return _body;
}

@end
