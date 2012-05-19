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
#import "HUD.h"

#define PTM_RATIO   32.0
#define SOFTLAYER NO

// game state
typedef enum
{
	kGameStatePaused,
	kGameStatePlaying,
	kGameStateGameOver
} GameState;

@interface Game : CCLayer
{
	CCSprite *background_;
    Terrain *terrain_;
    Paddle *paddle_;
    b2World *world_;
    b2Fixture *ballFixture_;
    NSMutableArray *obstacles_;
    NSMutableArray *ballBullets_;
    float addObstacleInterval_;
    MyContactListener *contactListener_;
    GameState gameState_;
    HUD *hud_;
}

+(CCScene *) scene;

@property (readonly,nonatomic) GameState gameState;
@property (readwrite, nonatomic, assign) HUD *hud;

@end
