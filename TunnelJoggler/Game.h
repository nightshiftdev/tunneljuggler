//
//  Game.h
//  TunnelJoggler
//

#import "cocos2d.h"
#import "Box2D.h"
#import "Terrain.h"
#import "Paddle.h"
#import "Obstacle.h"
#import "BallBullet.h"
#import "MyContactListener.h"

#define PTM_RATIO   32.0
#define SOFTLAYER NO


@interface Game : CCLayer
{
	CCSprite * _background;
    Terrain * _terrain;
    Paddle * _paddle;
    b2World *_world;
    b2Fixture *_ballFixture;
    NSMutableArray *_obstacles;
    NSMutableArray *_ballBullets;
    float _addObstacleInterval;
    MyContactListener *_contactListener;
}

+(CCScene *) scene;

@end
