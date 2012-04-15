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

@synthesize horizontalForce;
@synthesize decreaseHorizontalForceToZero;

- (void)createBody {
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CGFloat startPosition = self.contentSize.width;
    
    // Create paddle body
    b2BodyDef paddleBodyDef;
    paddleBodyDef.type = b2_dynamicBody;
    paddleBodyDef.position.Set(startPosition/PTM_RATIO, winSize.height/2/PTM_RATIO);
    paddleBodyDef.userData = self;
    _body = _world->CreateBody(&paddleBodyDef);
    
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
    _body->CreateFixture(&paddleShapeDef);
}

- (id)initWithWorld:(b2World *)world {
    if ((self = [super initWithSpriteFrameName:@"Paddle.png"])) {
        _world = world;
        [self createBody];
    }
    return self;
}

- (void)setDecreaseHorizontalForceToZero:(BOOL)decrease {
    if (decrease) {
        decreaseRate = fabs(horizontalForce/40);
    }
    decreaseHorizontalForceToZero = decrease;
}

- (void)update:(ccTime)dt {
    if(decreaseHorizontalForceToZero) {
        if (horizontalForce > 0) {
            horizontalForce -= decreaseRate;
        } else {
            horizontalForce += decreaseRate;
        }
//        NSLog(@"decrease rate %f ", decreaseRate);
//        NSLog(@"horizontalForce %f ", horizontalForce);
        if (fabs(horizontalForce) < decreaseRate) {
            decreaseHorizontalForceToZero = NO;
            horizontalForce = 0;
        }
    }
    
    static float offset = 0;
    offset += 1;
    _body->SetLinearVelocity(b2Vec2(-(_body->GetPosition().x*PTM_RATIO - offset), horizontalForce));
    self.position = ccp(_body->GetPosition().x*PTM_RATIO, _body->GetPosition().y*PTM_RATIO);
}

- (b2Body *) body {
    return _body;
}

- (void) setHorizontalForce:(float)force {
    horizontalForce = force;
}

@end