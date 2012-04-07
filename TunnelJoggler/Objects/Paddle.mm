//
//  Paddle.mm
//
//  Created by pawel on 2/28/12.
//

#import "Game.h"
#import "Paddle.h"

@implementation Paddle

@synthesize yPos;

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

- (void)update {
    static float offset = 0;
    offset += 1;
    _body->SetLinearVelocity(b2Vec2(-(_body->GetPosition().x*PTM_RATIO - offset), 0));
    self.position = ccp(_body->GetPosition().x*PTM_RATIO, _body->GetPosition().y*PTM_RATIO);
}

@end