//
//  Obstacle.m
//  TunnelJoggler
//
//  Created by pawel on 4/15/12.
//  Copyright (c) 2012 Pawel Kijowski. All rights reserved.
//

#import "Game.h"
#import "Obstacle.h"

@implementation Obstacle

@synthesize emitter;
@synthesize game;
@synthesize isMoving;
@synthesize horizontalForce;
@synthesize changeDirectionTimeIterval;

- (void)createBodyAtPosition: (CGPoint) position {
    // Create obstacle body
    b2BodyDef paddleBodyDef;
    paddleBodyDef.type = b2_kinematicBody;
    paddleBodyDef.position.Set(position.x/PTM_RATIO, position.y/PTM_RATIO);
    self.tag = kObstacleObject;
    paddleBodyDef.userData = self;
    body_ = world_->CreateBody(&paddleBodyDef);
    
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
    body_->CreateFixture(&paddleShapeDef);
}

- (id)initWithWorld:(b2World *)world position: (CGPoint) position game: (Game *) g {
    int iconIndex = arc4random() % 2;
    NSString *blockGraphicName =  [NSString stringWithFormat:@"block-%d.png", iconIndex];
    if ((self = [super initWithSpriteFrameName:blockGraphicName])) {
        self.game = g;
        self.isMoving = NO;
        self.horizontalForce = 0.0;
        self.changeDirectionTimeIterval = 0.0;
        world_ = world;
        [self createBodyAtPosition:position];
    }
    return self;
}

- (void)setChangeDirectionTimeIterval:(float)newChangeDirectionTimeIterval {
    changeDirectionTimeIterval = newChangeDirectionTimeIterval;
    _currentChangeDirectionTimeIterval = changeDirectionTimeIterval;
}

- (void)update:(ccTime)dt {
    if (self.isMoving) {
        if ((_currentChangeDirectionTimeIterval -= dt) < 0) {
            _currentChangeDirectionTimeIterval = self.changeDirectionTimeIterval;
            static int directionChangeCounter = 0;
            directionChangeCounter++;
            if (directionChangeCounter % 2) {
                body_->SetLinearVelocity(b2Vec2(0, self.horizontalForce));
            } else {
                body_->SetLinearVelocity(b2Vec2(0, -self.horizontalForce));
            }
        }
    } else {
        body_->SetLinearVelocity(b2Vec2(0, 0));
    }
    self.position = ccp(body_->GetPosition().x*PTM_RATIO, body_->GetPosition().y*PTM_RATIO);
}

- (b2Body *) body {
    return body_;
}

- (void)explode {
    self.emitter = [CCParticleExplosion node];
	[self.game addChild: emitter z:1];
    float scale = 0.5;
    if (([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)) {
        scale = 1.0;
    }
    self.emitter.scale = scale;
    self.emitter.positionType = kCCPositionTypeRelative;
    float x = self.position.x + self.game.terrain.position.x;
    self.emitter.life = 0.1;
    self.emitter.position = CGPointMake(x, self.position.y);
}

- (void) dealloc {
	[emitter release];
	[super dealloc];	
}

@end
