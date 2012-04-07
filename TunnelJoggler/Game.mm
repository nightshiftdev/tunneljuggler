//
//  Game.mm
//  TinySeal
//

#import "Game.h"

@implementation Game

+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	Game *layer = [Game node];
	[scene addChild: layer];
	return scene;
}

-(CCSprite *)spriteWithColor:(ccColor4F)bgColor textureSize:(float)textureSize {
    
    // 1: Create new CCRenderTexture
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    
    // 2: Call CCRenderTexture:begin
    [rt beginWithClear:bgColor.r g:bgColor.g b:bgColor.b a:bgColor.a];
    
    // 3: Draw into the texture
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    float gradientAlpha = 0.7;    
    CGPoint vertices[4];
    ccColor4F colors[4];
    int nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0 };
    vertices[nVertices] = CGPointMake(textureSize, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(0, textureSize);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(textureSize, textureSize);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);
    
    CCSprite *noise = [CCSprite spriteWithFile:@"Noise.png"];
    [noise setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
    noise.position = ccp(textureSize/2, textureSize/2);
    [noise visit];
    
    // 4: Call CCRenderTexture:end
    [rt end];
    
    // 5: Create a new Sprite from the texture
    return [CCSprite spriteWithTexture:rt.sprite.texture];
    
}

-(CCSprite *)stripedSpriteWithColor1:(ccColor4F)c1 color2:(ccColor4F)c2 textureSize:(float)textureSize  stripes:(int)nStripes {
    
    // 1: Create new CCRenderTexture
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    
    // 2: Call CCRenderTexture:begin
    [rt beginWithClear:c1.r g:c1.g b:c1.b a:c1.a];
    
    // 3: Draw into the texture    
    
    // Layer 1: Stripes
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    glDisableClientState(GL_COLOR_ARRAY);
    
    CGPoint vertices[nStripes*6];
    int nVertices = 0;
    float x1 = -textureSize;
    float x2;
    float y1 = textureSize;
    float y2 = 0;
    float dx = textureSize / nStripes * 2;
    float stripeWidth = dx/2;
    for (int i=0; i<nStripes; i++) {
        x2 = x1 + textureSize;
        vertices[nVertices++] = CGPointMake(x1, y1);
        vertices[nVertices++] = CGPointMake(x1+stripeWidth, y1);
        vertices[nVertices++] = CGPointMake(x2, y2);
        vertices[nVertices++] = vertices[nVertices-2];
        vertices[nVertices++] = vertices[nVertices-2];
        vertices[nVertices++] = CGPointMake(x2+stripeWidth, y2);
        x1 += dx;
    }
    
    glColor4f(c2.r, c2.g, c2.b, c2.a);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_TRIANGLES, 0, (GLsizei)nVertices);
    
    // layer 2: gradient
    glEnableClientState(GL_COLOR_ARRAY);
    
    float gradientAlpha = 0.7;    
    ccColor4F colors[4];
    nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0 };
    vertices[nVertices] = CGPointMake(textureSize, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(0, textureSize);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(textureSize, textureSize);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    // layer 3: top highlight
    float borderWidth = textureSize/16;
    float borderAlpha = 0.3f;
    nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){1, 1, 1, borderAlpha};
    vertices[nVertices] = CGPointMake(textureSize, 0);
    colors[nVertices++] = (ccColor4F){1, 1, 1, borderAlpha};
    
    vertices[nVertices] = CGPointMake(0, borderWidth);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(textureSize, borderWidth);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glBlendFunc(GL_DST_COLOR, GL_ONE_MINUS_SRC_ALPHA);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    glEnableClientState(GL_COLOR_ARRAY);
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);
    
    // Layer 2: Noise    
    CCSprite *noise = [CCSprite spriteWithFile:@"Noise.png"];
    [noise setBlendFunc:(ccBlendFunc){GL_DST_COLOR, GL_ZERO}];
    noise.position = ccp(textureSize/2, textureSize/2);
    [noise visit];        
    
    // 4: Call CCRenderTexture:end
    [rt end];
    
    // 5: Create a new Sprite from the texture
    return [CCSprite spriteWithTexture:rt.sprite.texture];
    
}

- (ccColor4F)randomBrightColor {
    
    while (true) {
        float requiredBrightness = 192;
        ccColor4B randomColor = 
        ccc4(arc4random() % 255,
             arc4random() % 255, 
             arc4random() % 255, 
             255);
        if (randomColor.r > requiredBrightness || 
            randomColor.g > requiredBrightness ||
            randomColor.b > requiredBrightness) {
            return ccc4FFromccc4B(randomColor);
        }        
    }
    
}

- (void)genBackground {
    
    
    [_background removeFromParentAndCleanup:YES];
   
    ccColor4F bgColor = [self randomBrightColor];
     if (SOFTLAYER) {
         ccColor4B redColor = 
         ccc4(255,
              255, 
              255, 
              255);
         bgColor = ccc4FFromccc4B(redColor);
     }
    _background = [self spriteWithColor:bgColor textureSize:512];
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    _background.position = ccp(winSize.width/2, winSize.height/2);        
    ccTexParams tp = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
    [_background.texture setTexParameters:&tp];
    
    [self addChild:_background];
    ccColor4F color3 = [self randomBrightColor];
    ccColor4F color4 = [self randomBrightColor];
    
    if (SOFTLAYER) {
        ccColor4B blackColor = 
        ccc4(1,
             1, 
             1, 
             255);
        color3 = ccc4FFromccc4B(blackColor);
        ccColor4B redColor = 
        ccc4(255,
             0, 
             0, 
             255);
        color4 = ccc4FFromccc4B(redColor);
    }
    CCSprite *stripes = [self stripedSpriteWithColor1:color3 color2:color4 textureSize:512 stripes:4];
    ccTexParams tp2 = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_CLAMP_TO_EDGE};
    [stripes.texture setTexParameters:&tp2];
    _terrain.stripes = stripes;
    
}

- (void)setupWorld {    
    b2Vec2 gravity = b2Vec2(-7.0f, 0.0f);
    bool doSleep = true;
    _world = new b2World(gravity, doSleep);            
}

- (void)createTestBodyAtPostition:(CGPoint)position 
{
    
    b2BodyDef testBodyDef;
    testBodyDef.type = b2_dynamicBody;
    testBodyDef.position.Set(position.x/PTM_RATIO, position.y/PTM_RATIO);
    b2Body * testBody = _world->CreateBody(&testBodyDef);
    
    b2CircleShape testBodyShape;
    b2FixtureDef testFixtureDef;
    testBodyShape.m_radius = 5.0/PTM_RATIO;
    testFixtureDef.shape = &testBodyShape;
    testFixtureDef.density = 0.1;
    testFixtureDef.friction = 0.1;
    testFixtureDef.restitution = 1.0;
    testBody->CreateFixture(&testFixtureDef);
    
}

- (void) createInitialBall
{
    // Create sprite and add it to the layer
    CCSprite *ball = [CCSprite spriteWithFile:@"Ball.png" 
                                         rect:CGRectMake(0, 0, 52, 52)];
    ball.position = ccp(100, 100);
    ball.tag = 1;
    [self addChild:ball];
    
    // Create ball body 
    b2BodyDef ballBodyDef;
    ballBodyDef.type = b2_dynamicBody;
    ballBodyDef.position.Set(100/PTM_RATIO, 100/PTM_RATIO);
    ballBodyDef.userData = ball;
    b2Body * ballBody = _world->CreateBody(&ballBodyDef);
    
    // Create circle shape
    b2CircleShape circle;
    circle.m_radius = 26.0/PTM_RATIO;
    
    // Create shape definition and add to body
    b2FixtureDef ballShapeDef;
    ballShapeDef.shape = &circle;
    ballShapeDef.density = 1.0f;
    ballShapeDef.friction = 0.f;
    ballShapeDef.restitution = 1.0f;
    _ballFixture = ballBody->CreateFixture(&ballShapeDef);}

-(id) init {
    if((self=[super init])) {
        [self setupWorld];
        _terrain = [[[Terrain alloc] initWithWorld:_world] autorelease];
        _paddle = [[[Paddle alloc] initWithWorld:_world] autorelease];
        [self genBackground];
        [self addChild:_terrain z:1];
        [_terrain.batchNode addChild: _paddle];
        self.isTouchEnabled = YES;
        [self scheduleUpdate];
    }
    return self;
}

- (void)update:(ccTime)dt {
    static double UPDATE_INTERVAL = 1.0f/60.0f;
    static double MAX_CYCLES_PER_FRAME = 5;
    static double timeAccumulator = 0;
    
    timeAccumulator += dt;    
    if (timeAccumulator > (MAX_CYCLES_PER_FRAME * UPDATE_INTERVAL)) {
        timeAccumulator = UPDATE_INTERVAL;
    }    
    
    int32 velocityIterations = 3;
    int32 positionIterations = 2;
    while (timeAccumulator >= UPDATE_INTERVAL) {        
        timeAccumulator -= UPDATE_INTERVAL;        
        _world->Step(UPDATE_INTERVAL, 
                     velocityIterations, positionIterations);        
        _world->ClearForces();
        
    }
    
    
//    float PIXELS_PER_SECOND = 100;
//    static float offset = 0;
//    offset += PIXELS_PER_SECOND * dt;
//    
    
    [_paddle update];
    float offset = _paddle.position.x - _paddle.contentSize.width;
    if (offset < 0) {
        offset = 1;
    }
    CGSize textureSize = _background.textureRect.size;
    [_background setTextureRect:CGRectMake(offset, 0, textureSize.width, textureSize.height)];
    [_terrain setOffsetX:offset];
}

- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    [self genBackground];
    
    UITouch *anyTouch = [touches anyObject];
    CGPoint touchLocation = [_terrain convertTouchToNodeSpace:anyTouch];
    [self createTestBodyAtPostition:touchLocation];
}

//- (void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//	
//    if (_mouseJoint != NULL) return;
//	
//    UITouch *myTouch = [touches anyObject];
//    CGPoint location = [myTouch locationInView:[myTouch view]];
//    location = [[CCDirector sharedDirector] convertToGL:location];
//    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
//	
//    if (_paddleFixture->TestPoint(locationWorld)) {
//        b2MouseJointDef md;
//        md.bodyA = _groundBody;
//        md.bodyB = _paddleBody;
//        md.target = locationWorld;
//        md.collideConnected = true;
//        md.maxForce = 1000.0f * _paddleBody->GetMass();
//		
//        _mouseJoint = (b2MouseJoint *)_world->CreateJoint(&md);
//        _paddleBody->SetAwake(true);
//    }
//	
//}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

//    if (_mouseJoint == NULL) return;
    
    UITouch *myTouch = [touches anyObject];
	
//	CGFloat panX = self.position.x - (prevPT.x - currPT.x);
//	
//	if (panX > 0) {
//		panX = 0;
//	}
//	
//	if (panX < -480.0f) {
//		panX = -480.0f;
//	}
    
    
    
    
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    
    
    float sign = -1;
    CGPoint prevPT = [myTouch previousLocationInView:myTouch.view];
	CGPoint currPT = [myTouch locationInView:myTouch.view];
    if (currPT.y > prevPT.y) {
        sign = 1;
    }
    
    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, sign * location.y/PTM_RATIO);
    NSLog(@"yPos: %f", locationWorld.y);
    [_paddle setYPos: locationWorld.y];
//    _mouseJoint->SetTarget(locationWorld);

    
//    if (_mouseJoint == NULL) return;
//    
//    UITouch *myTouch = [touches anyObject];
//    CGPoint location = [myTouch locationInView:[myTouch view]];
//    location = [[CCDirector sharedDirector] convertToGL:location];
//    b2Vec2 locationWorld = b2Vec2(location.x/PTM_RATIO, location.y/PTM_RATIO);
//    
//    _mouseJoint->SetTarget(locationWorld);
    
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	
//    if (_mouseJoint) {
//        _world->DestroyJoint(_mouseJoint);
//        _mouseJoint = NULL;
//    }
	
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    if (_mouseJoint) {
//        _world->DestroyJoint(_mouseJoint);
//        _mouseJoint = NULL;
//    }  
}

- (void)dealloc {
	
    delete _world;
//	delete _contactListener;
//    _groundBody = NULL;
    [super dealloc];
	
}

@end
