//
//  Paddle.h
//
//  Created by pawel on 2/28/12.
//

#import "cocos2d.h"
#import "Box2D.h"

@interface Paddle : CCSprite {
    b2World *_world;
    b2Body *_body;
    BOOL _awake;
    float horizontalForce;
    float decreaseRate;
    BOOL decreaseHorizontalForceToZero;
}

- (id)initWithWorld:(b2World *)world;
- (void)update:(ccTime)dt;
- (b2Body *) body;

@property (assign, nonatomic) float horizontalForce;
@property (assign, nonatomic) BOOL decreaseHorizontalForceToZero;

@end
