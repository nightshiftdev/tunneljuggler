//
//  Player.h
//  TunnelJoggler
//
//  Created by pawel on 7/25/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Player : NSManagedObject

@property (nonatomic, retain) NSNumber * currentLevel;
@property (nonatomic, retain) NSNumber * experienceLevel;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) UIImage  * picture;
@property (nonatomic, retain) NSString * recordUUID;
@property (nonatomic, retain) NSNumber * score;
@property (nonatomic, retain) NSNumber * bonusItems;

@end
