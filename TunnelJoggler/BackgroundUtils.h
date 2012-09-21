//
//  BackgroundUtils.h
//  TunnelJoggler
//
//  Created by pawel on 7/29/12.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#define IS_IPHONE_5 ( [ [ UIScreen mainScreen ] bounds ].size.height == 568 )

@interface BackgroundUtils : NSObject

+ (ccColor4F) randomBrightColor;
+ (CCSprite *)spriteWithColor:(ccColor4F)bgColor textureSize:(float)textureSize;
+ (CCSprite *)stripedSpriteWithColor1:(ccColor4F)c1 color2:(ccColor4F)c2 textureSize:(float)textureSize  stripes:(int)nStripes;
+ (CCSprite *)genBackground;

@end
