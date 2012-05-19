//
//  Paddle.h
//
//  Created by pawel on 2/28/12.
//

#import "cocos2d.h"
#import "Box2D.h"

@interface Paddle : CCSprite {
    b2World *world_;
    b2Body *body_;
    BOOL awake_;
    float horizontalForce_;
    float decreaseRate_;
    BOOL decreaseHorizontalForceToZero_;
}

- (id)initWithWorld:(b2World *)world;
- (void)update:(ccTime)dt;
- (b2Body *) body;

@property (assign, nonatomic) float horizontalForce;
@property (assign, nonatomic) BOOL decreaseHorizontalForceToZero;

@end
