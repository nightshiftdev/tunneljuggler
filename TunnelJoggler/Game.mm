//
//  Game.mm
//  TunnelJoggler
//

#import "Game.h"
#import "SimpleAudioEngine.h"

@implementation Game

@synthesize gameState = gameState_;
@synthesize hud = _hud;
@synthesize terrain = terrain_;

+(CCScene *) scene {
	CCScene *scene = [CCScene node];
	Game *game = [Game node];
	HUD *hud = [HUD HUDWithGameNode:game];
	[scene addChild:hud z:10];
	game.hud = hud;
	[scene addChild:game];
	return scene;
}

-(id) init {
    if((self=[super init])) {
        [self setupWorld];
        
        gameState_ = kGameStatePaused;
        
        obstacles_ = [[NSMutableArray alloc] init];
        ballBullets_ = [[NSMutableArray alloc] init];
        terrain_ = [[[Terrain alloc] initWithWorld:world_] autorelease];
        paddle_ = [[[Paddle alloc] initWithWorld:world_] autorelease];
        
        [self genBackground];
        [self addChild:terrain_ z:1];
        [terrain_.batchNode addChild: paddle_];
        self.isTouchEnabled = YES;
        
        CGSize winSize = [CCDirector sharedDirector].winSize;
        [self createBallBulletAtPosition:ccp(winSize.width/2, winSize.height/2)];
        
        addObstacleInterval_ = 5.0;
        addBonusBallInterval_ = 15.0;
        timeAccumulator_ = 0;
        
        contactListener_ = new MyContactListener();
		world_->SetContactListener(contactListener_);
        
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"background-music-aac.caf"];
        
        [self scheduleUpdate];
    }
    return self;
}

-(void)resetGame {
    timeAccumulator_ = 0;
    CGSize winSize = [CCDirector sharedDirector].winSize;
    paddle_.position = CGPointMake(0, winSize.height/2/PTM_RATIO);
    paddle_.offset = 0;
    paddle_.paddleSpeed = MIN_PADDLE_SPEED;
    addObstacleInterval_ = 5.0;
    addBonusBallInterval_ = 15.0;
    [self createBallBulletAtPosition:ccp(winSize.width/2, winSize.height)];
}

- (void) onEnterTransitionDidFinish {
    [super onEnterTransitionDidFinish];
    gameState_ = kGameStatePlaying;
}

- (void)setupWorld {    
    b2Vec2 gravity = b2Vec2(-7.0f, 0.0f);
    bool doSleep = true;
    world_ = new b2World(gravity, doSleep);            
}

- (void)createBallBulletAtPosition:(CGPoint)position {
    BallBullet *bb = [[[BallBullet alloc] initWithWorld: world_ position: position game: self] autorelease];
    [terrain_.batchNode addChild: bb];
    [ballBullets_ addObject: bb];
}

- (BOOL) useNegativeSign {
    int randomNumber = (arc4random() % (30 + 1));
    if (randomNumber % 2) {
        return YES;
    }
    return NO;
}

- (void) addNextObstacle:(ccTime)dt {
    CGSize winSize = [CCDirector sharedDirector].winSize;
    if ((addObstacleInterval_ -= dt) < 0) {
        [paddle_ increasePaddleSpeed];
        addObstacleInterval_ = 5.0;
        float randomizeObstaclePos = arc4random() % 100;
        if ([self useNegativeSign]) {
            randomizeObstaclePos *= -1;
        }
        Obstacle *obstacle = [[[Obstacle alloc] initWithWorld: world_
                                                     position: CGPointMake(paddle_.position.x + winSize.width,
                                                                           (winSize.height/2) + randomizeObstaclePos)
                                                         game: self]
                              autorelease];
        [obstacles_ addObject: obstacle];
        [terrain_.batchNode addChild: obstacle];
    }
}

- (void) addNextBounusBall:(ccTime)dt {
    CGSize winSize = [CCDirector sharedDirector].winSize;
    if ((addBonusBallInterval_ -= dt) < 0) {
        addBonusBallInterval_ = 15.0;
        [self createBallBulletAtPosition: CGPointMake(paddle_.position.x + winSize.width, 
                                                      (winSize.height/2))];
    }
}

- (void)update:(ccTime)dt {
    if (self.gameState != kGameStatePaused) {
        [self addNextObstacle: dt];
        [self addNextBounusBall:dt];
        
        timeAccumulator_ += dt;
        if (timeAccumulator_ > (MAX_CYCLES_PER_FRAME * UPDATE_INTERVAL)) {
            timeAccumulator_ = UPDATE_INTERVAL;
        }    
        
        int32 velocityIterations = 3;
        int32 positionIterations = 2;
        while (timeAccumulator_ >= UPDATE_INTERVAL) {        
            timeAccumulator_ -= UPDATE_INTERVAL;
            world_->Step(UPDATE_INTERVAL, 
                         velocityIterations, positionIterations);        
            world_->ClearForces();
            
        }
        
        for (int index = 0; index < [ballBullets_ count]; index++) {
            BallBullet *bb = [ballBullets_ objectAtIndex: index];
            float bulletXPos = bb.body->GetPosition().x * PTM_RATIO;
            if (bulletXPos >= paddle_.position.x - (2*PADDLE_SCREEN_POS_OFFSET)) {
                [bb update: dt];
            } else {
                [bb resetEmitter];
                CCSprite *sprite = (CCSprite *)bb.body->GetUserData();
                sprite.visible = NO;
                [terrain_ removeChild:bb cleanup:YES];
                world_->DestroyBody(bb.body);
                [ballBullets_ removeObject: bb];
            }
        }
        
        [paddle_ update: dt];
        for (int index = 0; index < [obstacles_ count]; index++) {
            Obstacle *o = [obstacles_ objectAtIndex: index];
            float obstacleXPos = o.body->GetPosition().x * PTM_RATIO;
            if (obstacleXPos >= paddle_.position.x) {
                [o update:dt];
            } else {
                [terrain_ removeChild:o cleanup:YES];
                world_->DestroyBody(o.body);
                [obstacles_ removeObject: o];
            }
        }
        
        
        float offset = paddle_.position.x - paddle_.contentSize.height - PADDLE_SCREEN_POS_OFFSET;
        if (offset < 0) {
            offset = 0;
            offset += 1;
        }
        
//        NSLog(@"offset %f", offset);
        CGSize textureSize = background_.textureRect.size;
        [background_ setTextureRect:CGRectMake(offset, 0, textureSize.width, textureSize.height)];

        [terrain_ setOffsetX:offset];
        
        std::vector<b2Body *>toDestroy;
        std::vector<MyContact>::iterator pos;
        BOOL destroyPaddle = NO;
        for(pos = contactListener_->_contacts.begin(); pos != contactListener_->_contacts.end(); ++pos) {
//            NSLog(@"inside contact listener loop");
            MyContact contact = *pos;
            
            //        if ((contact.fixtureA == _bottomFixture && contact.fixtureB == _ballFixture) ||
            //            (contact.fixtureA == _ballFixture && contact.fixtureB == _bottomFixture)) {
            //            GameOverScene *gameOverScene = [GameOverScene node];
            //            [gameOverScene.layer.label setString:@"You Lose :["];
            //            [[CCDirector sharedDirector] replaceScene:gameOverScene];
            //        } 
            
            b2Body *bodyA = contact.fixtureA->GetBody();
            b2Body *bodyB = contact.fixtureB->GetBody();
            
//            NSLog(@"bodyA data %@", bodyA->GetUserData());
//            NSLog(@"bodyB data %@", bodyB->GetUserData());
            
            if (bodyA->GetUserData() != NULL && bodyB->GetUserData() != NULL) {
                CCSprite *spriteA = (CCSprite *) bodyA->GetUserData();
                CCSprite *spriteB = (CCSprite *) bodyB->GetUserData();
                
//                NSLog(@"A tag %d", spriteA.tag);
//                NSLog(@"B tag %d", spriteB.tag);
                
                // Sprite A = ball, Sprite B = Block
                if (spriteA.tag == 1 && spriteB.tag == 2) {
                    if (std::find(toDestroy.begin(), toDestroy.end(), bodyB) == toDestroy.end()) {
                        toDestroy.push_back(bodyB);
//                        NSLog(@"ball touched block bodyB");
                    }
                }
                // Sprite B = block, Sprite A = ball
                else if (spriteA.tag == 2 && spriteB.tag == 1) {
                    if (std::find(toDestroy.begin(), toDestroy.end(), bodyA) == toDestroy.end()) {
                        toDestroy.push_back(bodyA);
//                        NSLog(@"ball touched block bodyA");
                    }
                } else if (spriteA.tag == 2 && spriteB.tag == 3) {
                    if (std::find(toDestroy.begin(), toDestroy.end(), bodyA) == toDestroy.end()) {
                        toDestroy.push_back(bodyA); 
                        destroyPaddle = YES;
                    }
                } else if (spriteA.tag == 3 && spriteB.tag == 2) {
                    if (std::find(toDestroy.begin(), toDestroy.end(), bodyA) == toDestroy.end()) {
                        toDestroy.push_back(bodyA);
                        destroyPaddle = YES;
                    }
                } else if (spriteA.tag == 1 && spriteB.tag == 3) {
                    // ball touched paddle
                    [self.hud onUpdateScore:1];
                } else if (spriteA.tag == 3 && spriteB.tag == 1) {
                    // ball touched paddle
                    [self.hud onUpdateScore:1];
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
                [self.hud onUpdateScore:10];
                [terrain_ removeChild:sprite cleanup:YES];
                for (int index = 0; index < [obstacles_ count]; index++) {
                    Obstacle *o = [obstacles_ objectAtIndex: index];
                    if (o.body == body) {
                        [o explode];
                        CGPoint createBonusBulletPosition = CGPointMake(o.body->GetPosition().x * PTM_RATIO, o.body->GetPosition().y * PTM_RATIO);
                        [self createBallBulletAtPosition: createBonusBulletPosition];
                        [obstacles_ removeObject: o];
                        world_->DestroyBody(body);
                    }
                }
            }
        }
        
        if (destroyPaddle) {
            CCSprite *paddleSprite = (CCSprite *)paddle_.body->GetUserData();
            paddleSprite.visible = NO;
            [terrain_ removeChild: paddle_ cleanup: YES];
            world_->DestroyBody(paddle_.body);
            self.gameState = kGameStatePaused;
            [self.hud gameOver: NO touchedFatalObject: YES];
        }
        
    }
}

-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    
    paddle_.decreaseHorizontalForceToZero = NO;
    
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
    paddle_.horizontalForce = paddleTouchForce.y;
}

-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    paddle_.decreaseHorizontalForceToZero = YES;
}

- (void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    paddle_.decreaseHorizontalForceToZero = YES;
}

- (void)dealloc {
    delete world_;
    [obstacles_ release];
    delete contactListener_;
    [super dealloc];
}

#pragma mark - color utils

-(CCSprite *)spriteWithColor:(ccColor4F)bgColor textureSize:(float)textureSize {
    // 1: Create new CCRenderTexture
    CCRenderTexture *rt = [CCRenderTexture renderTextureWithWidth:textureSize height:textureSize];
    
    // 2: Call CCRenderTexture:begin
    [rt beginWithClear:bgColor.r g:bgColor.g b:bgColor.b a:bgColor.a];
    
    // 3: Draw into the texture
    glDisable(GL_TEXTURE_2D);
    glDisableClientState(GL_TEXTURE_COORD_ARRAY);
    
    float gradientAlpha = 0.1;    
    CGPoint vertices[4];
    ccColor4F colors[4];
    int nVertices = 0;
    
    float screenFactor = [CCDirector sharedDirector].contentScaleFactor;
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0 };
    vertices[nVertices] = CGPointMake(textureSize * screenFactor, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(0, textureSize * screenFactor);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(textureSize * screenFactor, textureSize * screenFactor);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    glEnableClientState(GL_TEXTURE_COORD_ARRAY);
    glEnable(GL_TEXTURE_2D);
    
    CCSprite *noise = [CCSprite spriteWithFile:@"Noise.png"];
    if (IPAD || [CCDirector sharedDirector].contentScaleFactor == 2) {
        noise = [CCSprite spriteWithFile:@"Noise_iPad.png"];
    }
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
    
    float screenFactor = [CCDirector sharedDirector].contentScaleFactor;
    
    int nVertices = 0;
    float x1 = -textureSize * screenFactor;
    float x2;
    float y1 = textureSize * screenFactor;
    float y2 = 0;
    float dx = (textureSize / nStripes * 2) * screenFactor;
    float stripeWidth = dx/2;

    for (int i=0; i<nStripes; i++) {
        x2 = (x1 + textureSize) * screenFactor;
        vertices[nVertices++] = CGPointMake(x1, y1);
        vertices[nVertices++] = CGPointMake((x1+stripeWidth), y1);
        vertices[nVertices++] = CGPointMake(x2, y2);
        vertices[nVertices++] = vertices[nVertices-2];
        vertices[nVertices++] = vertices[nVertices-2];
        vertices[nVertices++] = CGPointMake((x2+stripeWidth), y2);
        x1 += dx;
    }
    
    glColor4f(c2.r, c2.g, c2.b, c2.a);
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glDrawArrays(GL_TRIANGLES, 0, (GLsizei)nVertices);
    
    // layer 2: gradient
    glEnableClientState(GL_COLOR_ARRAY);
    
    float gradientAlpha = 0.6;    
    ccColor4F colors[4];
    nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0 };
    vertices[nVertices] = CGPointMake(textureSize * screenFactor, 0);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(0, textureSize * screenFactor);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    vertices[nVertices] = CGPointMake(textureSize * screenFactor, textureSize * screenFactor);
    colors[nVertices++] = (ccColor4F){0, 0, 0, gradientAlpha};
    
    glVertexPointer(2, GL_FLOAT, 0, vertices);
    glColorPointer(4, GL_FLOAT, 0, colors);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, (GLsizei)nVertices);
    
    // layer 3: top highlight
    float borderWidth = textureSize/16;
    float borderAlpha = 0.5f;///screenFactor;
    nVertices = 0;
    
    vertices[nVertices] = CGPointMake(0, 0);
    colors[nVertices++] = (ccColor4F){1, 1, 1, borderAlpha};
    vertices[nVertices] = CGPointMake(textureSize * screenFactor, 0);
    colors[nVertices++] = (ccColor4F){1, 1, 1, borderAlpha};
    
    vertices[nVertices] = CGPointMake(0, borderWidth);
    colors[nVertices++] = (ccColor4F){0, 0, 0, 0};
    vertices[nVertices] = CGPointMake(textureSize * screenFactor, borderWidth * screenFactor);
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
    if (IPAD || [CCDirector sharedDirector].contentScaleFactor == 2) {
        noise = [CCSprite spriteWithFile:@"Noise_iPad.png"];
    }
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
    [background_ removeFromParentAndCleanup:YES];
    
    ccColor4F bgColor = [self randomBrightColor];
    if (SOFTLAYER) {
        ccColor4B redColor = 
        ccc4(255,
             255, 
             255, 
             255);
        bgColor = ccc4FFromccc4B(redColor);
    }
    
    float textureSize = 512;
    if (IPAD) {
        textureSize = 1024;
    }
    
    background_ = [self spriteWithColor:bgColor textureSize:textureSize];
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    background_.position = ccp((winSize.width/2), (winSize.height/2));      
    ccTexParams tp = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_REPEAT};
    [background_.texture setTexParameters:&tp];
    
    [self addChild:background_];
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

    float screenFactor = [CCDirector sharedDirector].contentScaleFactor;
    CCSprite *stripes = [self stripedSpriteWithColor1:color3 color2:color4 textureSize:512 stripes: 4 * screenFactor];
    ccTexParams tp2 = {GL_LINEAR, GL_LINEAR, GL_REPEAT, GL_CLAMP_TO_EDGE};
    [stripes.texture setTexParameters:&tp2];
    terrain_.stripes = stripes;
}

@end
