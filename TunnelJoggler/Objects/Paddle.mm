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

- (void)createBody {
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CGFloat startPosition = self.contentSize.width;
    
    // Create paddle body
    b2BodyDef paddleBodyDef;
    paddleBodyDef.type = b2_dynamicBody;
    paddleBodyDef.position.Set(startPosition/PTM_RATIO, winSize.height/2/PTM_RATIO);
    self.tag = 3;
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
}

- (id)initWithWorld:(b2World *)world {
    if ((self = [super initWithSpriteFrameName:@"Paddle.png"])) {
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
    
    static float offset = 0;
    offset += 1;
    body_->SetLinearVelocity(b2Vec2(-(body_->GetPosition().x*PTM_RATIO - offset), horizontalForce_));
    self.position = ccp(body_->GetPosition().x*PTM_RATIO, body_->GetPosition().y*PTM_RATIO);
}

- (b2Body *) body {
    return body_;
}

- (void) sethorizontalForce_:(float)force {
    horizontalForce_ = force;
}

@end