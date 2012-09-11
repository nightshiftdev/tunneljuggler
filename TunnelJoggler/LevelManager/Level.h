//
//  Level.h
//  TunnelJoggler
//
//  Created by pawel on 9/10/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Level : NSManagedObject

@property (nonatomic, retain) NSNumber * bonusBallFrequency;
@property (nonatomic, retain) NSNumber * bonusItemFrequency;
@property (nonatomic, retain) NSNumber * haveMovingObstacles;
@property (nonatomic, retain) NSNumber * length;
@property (nonatomic, retain) NSNumber * levelNumber;
@property (nonatomic, retain) NSNumber * maxSpeed;
@property (nonatomic, retain) NSNumber * minSpeed;
@property (nonatomic, retain) NSNumber * mustReachEndOfLevelToPass;
@property (nonatomic, retain) NSNumber * obstacleFrequency;
@property (nonatomic, retain) NSNumber * scoreToPass;
@property (nonatomic, retain) NSNumber * speedIncreaseInterval;
@property (nonatomic, retain) NSNumber * speedIncreaseValue;
@property (nonatomic, retain) NSNumber * timeToSurviveToPass;
@property (nonatomic, retain) NSNumber * isBossLevel;

@end
