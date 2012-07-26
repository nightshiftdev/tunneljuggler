//
//  Terrain.m
//
//  Created by pawel on 2/28/12.
//

#import "Terrain.h"
#import "Game.h"

@interface Terrain()
@property (nonatomic, assign, readwrite) int maxHillKeyPoints;
@end

@implementation Terrain

@synthesize stripes = _stripes;
@synthesize batchNode = _batchNode;
@synthesize terrainObserver;
@synthesize maxHillKeyPoints;

- (void)setupDebugDraw {
    _debugDraw = new GLESDebugDraw(PTM_RATIO*[[CCDirector sharedDirector] contentScaleFactor]);
    _world->SetDebugDraw(_debugDraw);
    _debugDraw->SetFlags(b2DebugDraw::e_shapeBit | b2DebugDraw::e_jointBit);
}

- (id)initWithWorld:(b2World *)world terrainLength:(int)terrainLength {
    if ((self = [super init])) {
        _hillKeyPoints = [[NSMutableArray alloc] init];
        self.maxHillKeyPoints = terrainLength + 1;
        _world = world;
//        [self setupDebugDraw];
        [self generateHills];
        [self resetHillVertices];
        
        _batchNode = [CCSpriteBatchNode batchNodeWithFile:@"sprites.png"];
        [self addChild:_batchNode];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"sprites.plist"];
    }
    return self;
}

- (void) resetBox2DBody {
    
    if(_body) {
        _world->DestroyBody(_body);
    }
    
    b2BodyDef bd;
    bd.position.Set(0, 0);
    
    _body = _world->CreateBody(&bd);
    
    b2PolygonShape shape;
    
    b2Vec2 p1, p2;
    for (int i=0; i<_nBorderVertices-1; i++) {
        p1 = b2Vec2(_borderVertices[i].x/PTM_RATIO,_borderVertices[i].y/PTM_RATIO);
        p2 = b2Vec2(_borderVertices[i+1].x/PTM_RATIO,_borderVertices[i+1].y/PTM_RATIO);
        shape.SetAsEdge(p1, p2);
        _body->CreateFixture(&shape, 0);
    }
    
    b2Vec2 o1, o2;
    b2PolygonShape oShape;
    for (int i=0; i<_nOppositeBorderVertices-1; i++) {
        o1 = b2Vec2(_oppositeBorderVertices[i].x/PTM_RATIO,_oppositeBorderVertices[i].y/PTM_RATIO);
        o2 = b2Vec2(_oppositeBorderVertices[i+1].x/PTM_RATIO,_oppositeBorderVertices[i+1].y/PTM_RATIO);
        oShape.SetAsEdge(o1, o2);
        _body->CreateFixture(&oShape, 0);
    }
}

- (void)resetHillVertices {
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
//    NSLog(@"winSize w:%f h:%f", winSize.width, winSize.height);
    
    static int prevFromKeyPointI = -1;
    static int prevToKeyPointI = -1;
    
    // key points interval for drawing
    while ((_fromKeyPointI+1 < self.maxHillKeyPoints) && ([[_hillKeyPoints objectAtIndex:_fromKeyPointI+1] CGPointValue].x < _offsetX-winSize.width/8)) {
        _fromKeyPointI++;
    }
    while ((_toKeyPointI+1 < self.maxHillKeyPoints) && ([[_hillKeyPoints objectAtIndex: _toKeyPointI] CGPointValue].x < _offsetX+winSize.width*9/8)) {
        _toKeyPointI++;
    }
    
    if (prevFromKeyPointI != _fromKeyPointI || prevToKeyPointI != _toKeyPointI) {
        
        // vertices for visible area
        _nHillVertices = 0;
        _nOppositeHillVertices = 0;
        _nBorderVertices = 0;
        _nOppositeBorderVertices = 0;
        CGPoint p0, p1, pt0, pt1;
        CGPoint o0, o1, ot0, ot1;
        o0 = [[_hillKeyPoints objectAtIndex: _fromKeyPointI] CGPointValue];
        o0.y = winSize.height - [[_hillKeyPoints objectAtIndex: _fromKeyPointI] CGPointValue].y;
        p0 = [[_hillKeyPoints objectAtIndex: _fromKeyPointI] CGPointValue];
//        NSLog(@"p0.x %f, p0.y %f", p0.x, p0.y);
//        NSLog(@"o0.x %f, o0.y %f", o0.x, o0.y);
        for (int i=_fromKeyPointI+1; i<_toKeyPointI+1; i++) {
            p1 = [[_hillKeyPoints objectAtIndex: i] CGPointValue];
            o1 = [[_hillKeyPoints objectAtIndex: i] CGPointValue];
            o1.y = winSize.height - [[_hillKeyPoints objectAtIndex: i] CGPointValue].y;
//            NSLog(@"p1.x %f, p1.y %f", p1.x, p1.y);
//            NSLog(@"o1.x %f, o1.y %f", o1.x, o1.y);
            // triangle strip between p0 and p1
            int hSegments = floorf((o1.x-o0.x)/kHillSegmentWidth);
            float dxOp = (o1.x - o0.x) / hSegments;
            float daOp = M_PI / hSegments;
            float dx = (p1.x - p0.x) / hSegments;
            float da = M_PI / hSegments;
            float ymidOp = (o0.y + o1.y) / 2;
            float amplOp = (o0.y - o1.y) / 2;
            float ymid = (p0.y + p1.y) / 2;
            float ampl = (p0.y - p1.y) / 2;
            ot0 = o0;
            pt0 = p0;
            _borderVertices[_nBorderVertices] = pt0;
            _oppositeBorderVertices[_nOppositeBorderVertices] = ot0;
            for (int j=1; j<hSegments+1; j++) {
                ot1.x = o0.x + j*dxOp;
                ot1.y = ymidOp + amplOp * cosf(daOp*j);
                pt1.x = p0.x + j*dx;
                pt1.y = ymid + ampl * cosf(da*j);
                _borderVertices[_nBorderVertices++] = pt1;
                _oppositeBorderVertices[_nOppositeBorderVertices++] = ot1;
                
                float y = winSize.height;
                float screenFactor = [CCDirector sharedDirector].contentScaleFactor;
                float div = 512;
                
                float textureRotationFactor = 0.5;
                if (screenFactor == 2.0) {
                    textureRotationFactor = 0.1;
                }
                
                _oppositeHillVertices[_nOppositeHillVertices] = CGPointMake(ot0.x * screenFactor, y * screenFactor);
                _oppositeHillTexCoords[_nOppositeHillVertices++] = CGPointMake((ot0.y/div)  * screenFactor, textureRotationFactor);
                _oppositeHillVertices[_nOppositeHillVertices] = CGPointMake(ot1.x * screenFactor , y * screenFactor);
                _oppositeHillTexCoords[_nOppositeHillVertices++] = CGPointMake((ot1.y/div)  * screenFactor, textureRotationFactor);
                
                _oppositeHillVertices[_nOppositeHillVertices] = CGPointMake((ot0.x * screenFactor), (ot0.y * screenFactor));
                _oppositeHillTexCoords[_nOppositeHillVertices++] = CGPointMake((ot0.y/div) * screenFactor, 0.0f);
                _oppositeHillVertices[_nOppositeHillVertices] = CGPointMake((ot1.x * screenFactor), (ot1.y * screenFactor));
                _oppositeHillTexCoords[_nOppositeHillVertices++] = CGPointMake((ot1.y/div) * screenFactor, 0.0f);

                
                ot0 = ot1;
                
                _hillVertices[_nHillVertices] = CGPointMake((pt0.x * screenFactor), 0.0f);
                _hillTexCoords[_nHillVertices++] = CGPointMake((pt0.x/div) * screenFactor, textureRotationFactor);
                _hillVertices[_nHillVertices] = CGPointMake((pt1.x * screenFactor), 0.0f);
                _hillTexCoords[_nHillVertices++] = CGPointMake((pt1.x/div) * screenFactor, textureRotationFactor);

                _hillVertices[_nHillVertices] = CGPointMake((pt0.x * screenFactor), (pt0.y * screenFactor));
                _hillTexCoords[_nHillVertices++] = CGPointMake((pt0.x/div) * screenFactor, 0.0f);
                _hillVertices[_nHillVertices] = CGPointMake((pt1.x * screenFactor), (pt1.y * screenFactor));
                _hillTexCoords[_nHillVertices++] = CGPointMake((pt1.x/div) * screenFactor, 0.0f);                
                
                pt0 = pt1;
            }
            p0 = p1;
            o0 = o1;
        }
        
        prevFromKeyPointI = _fromKeyPointI;
        prevToKeyPointI = _toKeyPointI;
        [self resetBox2DBody];
    }
}

- (void) generateHills {
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    
    float minDX = 20;
    float minDY = 10;
    int rangeDX = 100;
    int rangeDY = 120;
    float divider = 10;
    float x = -minDX;
    float y = winSize.height/divider - minDY;
    
    float dy, ny;
    float sign = 1; // +1 - going up, -1 - going  down
    float paddingBottom = 5;
    
    for (int i=0; i< self.maxHillKeyPoints; i++) {
        [_hillKeyPoints addObject: [NSValue valueWithCGPoint: CGPointMake(x, y)]];
        if (i == 0) {
            x = 0;
            y = winSize.height/divider;
        } else {
            x += rand()%rangeDX+minDX;
            while(true) {
                dy = rand()%rangeDY+minDY;
                ny = y + dy*sign;
                if(ny < winSize.height/6 && ny > paddingBottom) {
                    break;   
                }
            }
            y = ny;
        }
        sign *= -1;
    }
}

- (void) draw {
    glBindTexture(GL_TEXTURE_2D, _stripes.texture.name);
    glDisableClientState(GL_COLOR_ARRAY);
    
    glColor4f(1, 1, 1, 1);
    glVertexPointer(2, GL_FLOAT, 0, _oppositeHillVertices);
    glTexCoordPointer(2, GL_FLOAT, 0, _oppositeHillTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)_nOppositeHillVertices);

    
    glColor4f(1, 1, 1, 1);
    glVertexPointer(2, GL_FLOAT, 0, _hillVertices);
    glTexCoordPointer(2, GL_FLOAT, 0, _hillTexCoords);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)_nHillVertices);
    
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_COLOR_ARRAY);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
//    _world->DrawDebugData();
    
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
}

- (void) setOffsetX:(float)newOffsetX {
    if (self.terrainObserver && _toKeyPointI+1 >= self.maxHillKeyPoints) {
        [self.terrainObserver onTerrainEnd: self];
        _toKeyPointI = 0;
        _fromKeyPointI = 0;
    } else {
        _offsetX = newOffsetX;
        self.position = CGPointMake(-_offsetX, 0);
        [self resetHillVertices];
    }
}

- (void)dealloc {
    [_hillKeyPoints release];
    _hillKeyPoints = nil;
    [_stripes release];
    _stripes = NULL;
    [super dealloc];
}
@end