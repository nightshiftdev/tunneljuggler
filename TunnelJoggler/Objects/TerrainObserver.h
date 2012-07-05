//
//  TerrainObserver.h
//  TunnelJoggler
//
//  Created by pawel on 7/2/12.
//
//

#import <Foundation/Foundation.h>

@class Terrain;

@protocol TerrainObserver <NSObject>
-(void)onTerrainEnd:(Terrain *) terrain;
@end
