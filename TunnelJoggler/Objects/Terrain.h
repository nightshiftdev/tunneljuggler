//
//  Terrain.h
//
//  Created by pawel on 2/28/12.
//  Copyright (c) 2012 Pawel Kijowski. All rights reserved.
//

#import "cocos2d.h"
#import "Box2D.h"
#import "GLES-Render.h"
#import "TerrainObserver.h"

#define IPAD NO
//#define IPAD_SCREEN


// controls the length of the level
#define kDefaultMaxHillKeyPoints 300
//#ifdef IPAD_SCREEN
//#define kHillSegmentWidth 8
//#else
#define kHillSegmentWidth 5
//#endif

#define kMaxHillVertices 800
#define kMaxBorderVertices 800

@interface Terrain : CCNode {
    @private
    int _offsetX;
//    CGPoint _hillKeyPoints[kMaxHillKeyPoints];
    CCSprite *_stripes;
    int _fromKeyPointI;
    int _toKeyPointI;
    int _nHillVertices;
    int _nOppositeHillVertices;
    CGPoint _hillVertices[kMaxHillVertices];
    CGPoint _hillTexCoords[kMaxHillVertices];
    CGPoint _oppositeHillVertices[kMaxHillVertices];
    CGPoint _oppositeHillTexCoords[kMaxHillVertices];
    CGPoint _borderVertices[kMaxBorderVertices];
    CGPoint _oppositeBorderVertices[kMaxBorderVertices];
    b2World *_world;
    b2Body *_body;
    GLESDebugDraw * _debugDraw;
    CCSpriteBatchNode * _batchNode;
    int _nBorderVertices;
    int _nOppositeBorderVertices;
    NSMutableArray *_hillKeyPoints;
}

@property (retain) CCSprite * stripes;
@property (retain) CCSpriteBatchNode * batchNode;
@property (nonatomic, retain) id<TerrainObserver> terrainObserver;
//@property (nonatomic, assign) int nBorderVertices;
//@property (nonatomic, assign) int nOppositeBorderVertices;
- (void)setOffsetX:(float)newOffsetX;
- (void)generateHills;
- (void)resetHillVertices;
- (id)initWithWorld:(b2World *)world terrainLength:(int)terrainLength;

@end
