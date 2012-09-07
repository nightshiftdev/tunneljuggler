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

#ifdef DEBUG
#define DEBUG_LOG YES
#else
#define DEBUG_LOG NO
#endif

typedef enum {
    kGameStatePaused = 0,
    kGameStateRunning,
} GameState;

static const double UPDATE_INTERVAL = 1.0f/60.0f;
static const double MAX_CYCLES_PER_FRAME = 5;

@class Player;
@class Level;

@interface Game : CCLayer <TerrainObserver>
{
	CCSprite *background_;
    Terrain *terrain_;
    Paddle *paddle_;
    b2World *world_;
    b2Fixture *ballFixture_;
    NSMutableArray *obstacles_;
    NSMutableArray *ballBullets_;
    float addObstacleInterval_;
    float addBonusBallInterval_;
    float increasePaddleSpeedInterval_;
    MyContactListener *contactListener_;
    HUD *_hud;
    Player *_player;
    Level *_currentLevel;
    double timeAccumulator_;
    float _paddleScreenPosOffset;
    float _oneSecond;
    float _updateLengthCounterInterval;
}

+(CCScene *)scene;
-(void)setupWorld;
-(void)genBackground;
-(void)createBallBulletAtPosition:(CGPoint)position;

@property (readwrite, nonatomic, assign) HUD *hud;
@property (readonly, nonatomic) Terrain *terrain;
@property (readwrite, nonatomic, assign) GameState state;

@end
