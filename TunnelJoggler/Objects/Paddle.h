//
//  Paddle.h
//
//  Created by pawel on 2/28/12.
//

#import "cocos2d.h"
#import "Box2D.h"

static const float MAX_PADDLE_SPEED = 8.0;
static const float MIN_PADDLE_SPEED = 1.0;

@class Game;

@interface Paddle : CCSprite {
    b2World *world_;
    b2Body *body_;
    CCParticleSystem *emitter;
    BOOL awake_;
    float horizontalForce_;
    float decreaseRate_;
    BOOL decreaseHorizontalForceToZero_;
    float offset_;
}

- (id)initWithWorld:(b2World *)world game: (Game *) g;
- (void)update:(ccTime)dt;
- (b2Body *) body;
- (void)increasePaddleSpeed;
- (void)explode;

@property (assign, nonatomic) float horizontalForce;
@property (assign, nonatomic) BOOL decreaseHorizontalForceToZero;
@property (nonatomic, assign) float offset;
@property (nonatomic, assign) float speed;
@property (nonatomic, assign) float maxSpeed;
@property (nonatomic, assign) float minSpeed;
@property (nonatomic, assign) float speedIncreaseAmount;
@property (nonatomic, readwrite, retain) CCParticleSystem *emitter;
@property (nonatomic, assign) Game *game;

@end
