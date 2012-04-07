//
//  Terrain.h
//
//  Created by pawel on 2/28/12.
//  Copyright (c) 2012 Ray Wenderlich. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"

#define kMaxHillKeyPoints 1000
#define kHillSegmentWidth 5

#define kMaxHillVertices 4000
#define kMaxBorderVertices 800

@interface Terrain : CCNode {
    int _offsetX;
    CGPoint _hillKeyPoints[kMaxHillKeyPoints];
    CCSprite *_stripes;
    int _fromKeyPointI;
    int _toKeyPointI;
    
    int _nHillVertices;
    int _nOppositeHillVertices;
    CGPoint _hillVertices[kMaxHillVertices];
    CGPoint _hillTexCoords[kMaxHillVertices];
    CGPoint _oppositeHillVertices[kMaxHillVertices];
    CGPoint _oppositeHillTexCoords[kMaxHillVertices];
    int _nBorderVertices;
    int _nOppositeBorderVertices;
    CGPoint _borderVertices[kMaxBorderVertices];
    CGPoint _oppositeBorderVertices[kMaxBorderVertices];
    b2World *_world;
    b2Body *_body;
    GLESDebugDraw * _debugDraw;
    CCSpriteBatchNode * _batchNode;
}

@property (retain) CCSprite * stripes;
@property (retain) CCSpriteBatchNode * batchNode;
- (void) setOffsetX:(float)newOffsetX;
- (void) generateHills;
- (void)resetHillVertices;
- (id)initWithWorld:(b2World *)world;

@end
