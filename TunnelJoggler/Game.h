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
static const float PADDLE_SCREEN_POS_OFFSET = 60;
static const double UPDATE_INTERVAL = 1.0f/60.0f;
static const double MAX_CYCLES_PER_FRAME = 5;

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
    float addBonusBallInterval_;
    MyContactListener *contactListener_;
    GameState gameState_;
    HUD *hud_;
    double timeAccumulator_;
}

+(CCScene *) scene;
-(void)setupWorld;
-(void)genBackground;
-(void)createBallBulletAtPosition:(CGPoint)position;
-(void)resetGame;

@property (readwrite,nonatomic) GameState gameState;
@property (readwrite, nonatomic, assign) HUD *hud;
@property (readonly, nonatomic) Terrain *terrain;

@end
