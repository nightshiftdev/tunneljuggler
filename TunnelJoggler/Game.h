//
//  Game.h
//  TinySeal
//

#import "cocos2d.h"
#import "Box2D.h"
#import "Terrain.h"

#define PTM_RATIO   32.0
#define SOFTLAYER NO


@interface Game : CCLayer
{
	CCSprite * _background;
    Terrain * _terrain;
    b2World *_world;
}

+(CCScene *) scene;

@end
