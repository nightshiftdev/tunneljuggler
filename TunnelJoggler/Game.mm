//
//  Game.mm
//  TunnelJoggler
//

#import "Game.h"
#import "SimpleAudioEngine.h"

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

- (void)createBallBulletAtPosition:(CGPoint)position
{
    BallBullet *bb = [[BallBullet alloc] initWithWorld: _world position: position];
    [_terrain.batchNode addChild: bb];
    [_ballBullets addObject: bb];
}

-(id) init {
    if((self=[super init])) {
        [self setupWorld];
        _obstacles = [[NSMutableArray alloc] init];
        _ballBullets = [[NSMutableArray alloc] init];
        _terrain = [[[Terrain alloc] initWithWorld:_world] autorelease];
        _paddle = [[[Paddle alloc] initWithWorld:_world] autorelease];
        
        [self genBackground];
        [self addChild:_terrain z:1];
        [_terrain.batchNode addChild: _paddle];
        self.isTouchEnabled = YES;
        
        CGSize winSize = [CCDirector sharedDirector].winSize;
        [self createBallBulletAtPosition:ccp(winSize.width, winSize.height/4)];
        [self createBallBulletAtPosition:ccp(winSize.width - 10, winSize.height/6)];
        [self createBallBulletAtPosition:ccp(winSize.width/2, winSize.height/2)];
        
        _addObstacleInterval = 5.0;
        
        _contactListener = new MyContactListener();
		_world->SetContactListener(_contactListener);
        
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background-music-aac.caf"];
        
        [self scheduleUpdate];
    }
    return self;
}

- (void)update:(ccTime)dt {
    CGSize winSize = [CCDirector sharedDirector].winSize;
    if ((_addObstacleInterval -= dt) < 0) {
        _addObstacleInterval = 5.0;
        Obstacle *obstacle = [[[Obstacle alloc] initWithWorld: _world position: CGPointMake(_paddle.position.x + winSize.width, winSize.height/2)] autorelease];
        [_obstacles addObject: obstacle];
        [_terrain.batchNode addChild: obstacle];
    }
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
    
    for (BallBullet *bb in _ballBullets) {
        [bb update: dt];
    }
    
    [_paddle update: dt];
    for (int index = 0; index < [_obstacles count]; index++) {
        Obstacle *o = [_obstacles objectAtIndex: index];
        float obstacleXPos = o.body->GetPosition().x*PTM_RATIO;
        if (obstacleXPos >= _paddle.position.x) {
            [o update:dt];
        }
        else {
            [_terrain removeChild:o cleanup:YES];
            _world->DestroyBody(o.body);
            [_obstacles removeObject: o];
        }
    }
    
    float offset = _paddle.position.x - _paddle.contentSize.width;
    CGSize textureSize = _background.textureRect.size;
    [_background setTextureRect:CGRectMake(offset, 0, textureSize.width, textureSize.height)];
    [_terrain setOffsetX:offset];
    
    
    std::vector<b2Body *>toDestroy;
    std::vector<MyContact>::iterator pos;
    for(pos = _contactListener->_contacts.begin(); pos != _contactListener->_contacts.end(); ++pos) {
        NSLog(@"inside contact listener loop");
        MyContact contact = *pos;
        
//        if ((contact.fixtureA == _bottomFixture && contact.fixtureB == _ballFixture) ||
//            (contact.fixtureA == _ballFixture && contact.fixtureB == _bottomFixture)) {
//            GameOverScene *gameOverScene = [GameOverScene node];
//            [gameOverScene.layer.label setString:@"You Lose :["];
//            [[CCDirector sharedDirector] replaceScene:gameOverScene];
//        } 
		
        b2Body *bodyA = contact.fixtureA->GetBody();
        b2Body *bodyB = contact.fixtureB->GetBody();
        
        NSLog(@"bodyA data %@", bodyA->GetUserData());
        NSLog(@"bodyB data %@", bodyB->GetUserData());
        
        if (bodyA->GetUserData() != NULL && bodyB->GetUserData() != NULL) {
            CCSprite *spriteA = (CCSprite *) bodyA->GetUserData();
            CCSprite *spriteB = (CCSprite *) bodyB->GetUserData();
        
            NSLog(@"A tag %d", spriteA.tag);
            NSLog(@"B tag %d", spriteB.tag);
            
            // Sprite A = ball, Sprite B = Block
            if (spriteA.tag == 1 && spriteB.tag == 2) {
                if (std::find(toDestroy.begin(), toDestroy.end(), bodyB) == toDestroy.end()) {
                    toDestroy.push_back(bodyB);
                    NSLog(@"ball touched block bodyB");
                }
            }
            // Sprite B = block, Sprite A = ball
            else if (spriteA.tag == 2 && spriteB.tag == 1) {
                if (std::find(toDestroy.begin(), toDestroy.end(), bodyA) == toDestroy.end()) {
                    toDestroy.push_back(bodyA);
                    NSLog(@"ball touched block bodyA");
                }
            }
            else if (spriteA.tag == 2 && spriteB.tag == 3) {
                if (std::find(toDestroy.begin(), toDestroy.end(), bodyA) == toDestroy.end()) {
                    toDestroy.push_back(bodyA);
                    NSLog(@"GAME OVER paddle touched obstacle bodyB");
                }
            }
            else if (spriteA.tag == 3 && spriteB.tag == 2) {
                if (std::find(toDestroy.begin(), toDestroy.end(), bodyA) == toDestroy.end()) {
                    toDestroy.push_back(bodyA);
                    NSLog(@"GAME OVER paddle touched obstacle bodyA");
                }
            }
        
        }                 
    }
	
    std::vector<b2Body *>::iterator pos2;
    for(pos2 = toDestroy.begin(); pos2 != toDestroy.end(); ++pos2) {
        b2Body *body = *pos2;     
        if (body->GetUserData() != NULL) {
            CCSprite *sprite = (CCSprite *) body->GetUserData();
            sprite.visible = NO;
            [[SimpleAudioEngine sharedEngine] playEffect:@"blip.caf"];
            [_terrain removeChild:sprite cleanup:YES];
            for (int index = 0; index < [_obstacles count]; index++) {
                Obstacle *o = [_obstacles objectAtIndex: index];
                if (o.body == body) {
                    [_obstacles removeObject: o];
                    _world->DestroyBody(body);
                }
            }
        }
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    _paddle.decreaseHorizontalForceToZero = NO;
    
    UITouch *myTouch = [touches anyObject];    
    
    CGPoint location = [myTouch locationInView:[myTouch view]];
    location = [[CCDirector sharedDirector] convertToGL:location];
    
    float sign = -1;
    CGPoint prevPT = [myTouch previousLocationInView:myTouch.view];
	CGPoint currPT = [myTouch locationInView:myTouch.view];
    
    float force = fabs(prevPT.y - currPT.y);
    if (currPT.y > prevPT.y) {
        sign = 1;
    }
    
    b2Vec2 paddleTouchForce = b2Vec2(0.0, sign * force);
    _paddle.horizontalForce = paddleTouchForce.y;
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    _paddle.decreaseHorizontalForceToZero = YES;
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    _paddle.decreaseHorizontalForceToZero = YES;
}

- (void)dealloc {
    delete _world;
    [_obstacles release];
    delete _contactListener;
    [super dealloc];
	
}

@end
