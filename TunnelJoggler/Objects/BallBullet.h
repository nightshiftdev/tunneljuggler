//
//  BallBullet.h
//  TunnelJoggler
//
//  Created by pawel on 4/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Box2D.h"
#import "CCSprite.h"

@interface BallBullet : CCSprite {
    b2World *_world;
    b2Body *_body;
}

- (id)initWithWorld:(b2World *)world position: (CGPoint) position;
- (void)update:(ccTime)dt;
- (b2Body *) body;

@end
