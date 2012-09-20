//
//  Paddle.mm
//
//  Created by pawel on 2/28/12.
//

#import "Game.h"
#import "Paddle.h"

#ifndef M_PI_X_2
#define M_PI_X_2 (float)M_PI * 2.0f
#endif

@implementation Paddle

@synthesize horizontalForce = horizontalForce_;
@synthesize decreaseHorizontalForceToZero = decreaseHorizontalForceToZero_;
@synthesize offset = offset_;
@synthesize speed;
@synthesize minSpeed;
@synthesize maxSpeed;
@synthesize speedIncreaseAmount;
@synthesize emitter;
@synthesize game;

- (void)createBody {
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CGFloat startPosition = self.contentSize.width;
    self.offset = 0;

    // Create paddle body
    b2BodyDef paddleBodyDef;
    paddleBodyDef.type = b2_dynamicBody;
    paddleBodyDef.position.Set(startPosition/PTM_RATIO, winSize.height/2/PTM_RATIO);
    self.tag = kPaddleObject;
    paddleBodyDef.userData = self;
    body_ = world_->CreateBody(&paddleBodyDef);
    
    // Create paddle shape
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
    
    self.maxSpeed = MAX_PADDLE_SPEED;
    self.minSpeed = MIN_PADDLE_SPEED;
    self.speed = self.minSpeed;
    self.speedIncreaseAmount = 0.1;
}

- (id)initWithWorld:(b2World *)world game: (Game *) g {
    NSString *paddleGraphicName = @"paddle-1.png";
    if ((self = [super initWithSpriteFrameName: paddleGraphicName])) {
        _emitterLife = 0.1;
        self.game = g;
        world_ = world;
        [self createBody];
    }
    return self;
}

- (void)setDecreaseHorizontalForceToZero:(BOOL)decrease {
    if (decrease) {
        decreaseRate_ = fabs(horizontalForce_/40);
    }
    decreaseHorizontalForceToZero_ = decrease;
}

- (void) removeEmitter:(ccTime)dt {
    if ((_emitterLife -= dt) < 0 || (horizontalForce_ == 0)) {
        if (self.emitter) {
            [self.game removeChild:self.emitter cleanup:YES];
            self.emitter = nil;
        }
    }
}

- (void)update:(ccTime)dt {
    if(decreaseHorizontalForceToZero_) {
        if (horizontalForce_ > 0) {
            horizontalForce_ -= decreaseRate_;
        } else {
            horizontalForce_ += decreaseRate_;
        }
        if (fabs(horizontalForce_) < decreaseRate_) {
            decreaseHorizontalForceToZero_ = NO;
            horizontalForce_ = 0;
        }
    }
    self.offset += self.speed;
    body_->SetLinearVelocity(b2Vec2(-(body_->GetPosition().x*PTM_RATIO - self.offset), horizontalForce_));
    self.position = ccp(body_->GetPosition().x*PTM_RATIO, body_->GetPosition().y*PTM_RATIO);
    [self removeEmitter:dt];
}

- (b2Body *) body {
    return body_;
}

- (void) setHorizontalForce_:(float)force {
    horizontalForce_ = force;
}

- (void) setSpeed:(float)newSpeed {
    speed = newSpeed;
    if (speed > self.maxSpeed) {
        speed = self.maxSpeed;
    }
    
    if (speed < self.minSpeed) {
        speed = self.minSpeed;
    }
}

- (void)increasePaddleSpeed {
    self.speed += self.speedIncreaseAmount;
}

- (void)bumpedTerrain {
    if (!self.emitter && fabs(horizontalForce_) > 0) {
        _emitterLife = 0.1;
        self.emitter = [CCParticleFire node];
        [self.game addChild: emitter z:1];
        self.emitter.scale = 0.3;
        float x = self.position.x + self.game.terrain.position.x;
        float y = self.position.y;
        if (horizontalForce_ > 0) {
            y += self.contentSize.height/2;
        } else {
            y -= self.contentSize.height/2;
        }
        self.emitter.position = CGPointMake(x - 2*self.contentSize.width, y);
        self.emitter.positionType = kCCPositionTypeRelative;
    }
}

- (void) dealloc {
	[emitter release];
	[super dealloc];	
}

@end