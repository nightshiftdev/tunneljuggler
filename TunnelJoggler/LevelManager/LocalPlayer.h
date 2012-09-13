//
//  LocalPlayer.h
//  TunnelJoggler
//
//  Created by pawel on 8/20/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface LocalPlayer : NSManagedObject

@property (nonatomic, retain) NSNumber * bonusItems;
@property (nonatomic, retain) NSNumber * currentLevel;
@property (nonatomic, retain) NSNumber * experienceLevel;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * score;
@property (nonatomic, retain) NSString * token;

@end