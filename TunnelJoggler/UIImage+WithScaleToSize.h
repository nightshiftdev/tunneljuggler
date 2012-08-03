//
//  UIImage+WithScaleToSize.h
//  TunnelJoggler
//
//  Created by pawel on 8/3/12.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (WithScaleToSize)
+(UIImage *)makeRoundCornerImage : (UIImage*) img : (int) cornerWidth : (int) cornerHeight;
- (UIImage *) scaleToSize: (CGSize)size;
- (UIImage *) scaleProportionalToSize: (CGSize)size;
@end
