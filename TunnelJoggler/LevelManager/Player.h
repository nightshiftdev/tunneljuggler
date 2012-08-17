//
//  Player.h
//  TunnelJoggler
//
//  Created by pawel on 8/16/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Player : NSManagedObject

@property (nonatomic, retain) NSNumber * bonusItems;
@property (nonatomic, retain) NSNumber * currentLevel;
@property (nonatomic, retain) NSNumber * experienceLevel;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * score;

@end
