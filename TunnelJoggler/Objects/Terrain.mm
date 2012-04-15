//
//  Terrain.m
//
//  Created by pawel on 2/28/12.
//

#import "Terrain.h"
#import "Game.h"

@implementation Terrain

@synthesize stripes = _stripes;
@synthesize batchNode = _batchNode;

- (void)setupDebugDraw {    
    _debugDraw = new GLESDebugDraw(PTM_RATIO*[[CCDirector sharedDirector] contentScaleFactor]);
    _world->SetDebugDraw(_debugDraw);
    _debugDraw->SetFlags(b2DebugDraw::e_shapeBit | b2DebugDraw::e_jointBit);
}

- (id)initWithWorld:(b2World *)world {
    if ((self = [super init])) {
        _world = world;
        [self setupDebugDraw];
        [self generateHills];
        [self resetHillVertices];
        
        _batchNode = [CCSpriteBatchNode batchNodeWithFile:@"TunnelJoggler.png"];
        [self addChild:_batchNode];
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"TunnelJoggler.plist"];
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
    
    static int prevFromKeyPointI = -1;
    static int prevToKeyPointI = -1;
    
    // key points interval for drawing
    while (_hillKeyPoints[_fromKeyPointI+1].x < _offsetX-winSize.width/8/self.scale) {
        _fromKeyPointI++;
    }
    while (_hillKeyPoints[_toKeyPointI].x < _offsetX+winSize.width*9/8/self.scale) {
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
        o0 = _hillKeyPoints[_fromKeyPointI];
        o0.y = winSize.height - _hillKeyPoints[_fromKeyPointI].y;
        p0 = _hillKeyPoints[_fromKeyPointI];
//        NSLog(@"p0.x %f, p0.y %f", p0.x, p0.y);
//        NSLog(@"o0.x %f, o0.y %f", o0.x, o0.y);
        for (int i=_fromKeyPointI+1; i<_toKeyPointI+1; i++) {
            p1 = _hillKeyPoints[i];
            o1 = _hillKeyPoints[i];
            o1.y = winSize.height - _hillKeyPoints[i].y; 
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
                float div = 512;
                _oppositeHillVertices[_nOppositeHillVertices] = CGPointMake(ot0.x, y);
                _oppositeHillTexCoords[_nOppositeHillVertices++] = CGPointMake(1.0f, ot0.y/div);
                _oppositeHillVertices[_nOppositeHillVertices] = CGPointMake(ot1.x, y);
                _oppositeHillTexCoords[_nOppositeHillVertices++] = CGPointMake(1.0f, ot1.y/div);
                
                _oppositeHillVertices[_nOppositeHillVertices] = CGPointMake(ot0.x, ot0.y);
                _oppositeHillTexCoords[_nOppositeHillVertices++] = CGPointMake(0, ot0.y/div);
                _oppositeHillVertices[_nOppositeHillVertices] = CGPointMake(ot1.x, ot1.y);
                _oppositeHillTexCoords[_nOppositeHillVertices++] = CGPointMake(0, ot1.y/div);
                
                ot0 = ot1;
                
                _hillVertices[_nHillVertices] = CGPointMake(pt0.x, 0);
                _hillTexCoords[_nHillVertices++] = CGPointMake(pt0.x/512, 1.0f);
                _hillVertices[_nHillVertices] = CGPointMake(pt1.x, 0);
                _hillTexCoords[_nHillVertices++] = CGPointMake(pt1.x/512, 1.0f);

                _hillVertices[_nHillVertices] = CGPointMake(pt0.x, pt0.y);
                _hillTexCoords[_nHillVertices++] = CGPointMake(pt0.x/512, 0);
                _hillVertices[_nHillVertices] = CGPointMake(pt1.x, pt1.y);
                _hillTexCoords[_nHillVertices++] = CGPointMake(pt1.x/512, 0);                
                
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
    
    for (int i=0; i<kMaxHillKeyPoints; i++) {
        _hillKeyPoints[i] = CGPointMake(x, y);
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
    
    _world->DrawDebugData();
    
    glEnable(GL_TEXTURE_2D);
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
}

- (void) setOffsetX:(float)newOffsetX {
    _offsetX = newOffsetX;
    self.position = CGPointMake(-_offsetX*self.scale, 0);
    [self resetHillVertices];
}

- (void)dealloc {
    [_stripes release];
    _stripes = NULL;
    [super dealloc];
}
@end