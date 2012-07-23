//
//  GameController.h
//  TunnelJoggler
//
//  Created by pawel on 7/10/12.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "Player.h"

@interface GameController : NSObject <NSFilePresenter>
{
@private
    Player *_player;
    NSArray *_levels;
    NSPersistentStoreCoordinator *_psc;
    NSManagedObjectContext *_mainThreadContext;
    NSPersistentStore *_playeriCloudStore;
    NSPersistentStore *_playerFallbackStore;
    NSPersistentStore *_levelsLocalStore;
    id _currentUbiquityToken;
    NSLock *_loadingLock;
    NSURL *_presentedItemURL;
    NSURL *_ubiquityURL;
}

// game logic
@property (retain, nonatomic) Player *player;
@property (retain, nonatomic, readonly) NSArray *levels;

// data managment
@property (nonatomic, readonly) NSPersistentStoreCoordinator *psc;
@property (nonatomic, readonly) NSManagedObjectContext *mainThreadContext;
@property (nonatomic, readonly) NSPersistentStore *playeriCloudStore;
@property (nonatomic, readonly) NSPersistentStore *playerFallbackStore;
@property (nonatomic, readonly) NSPersistentStore *levelsLocalStore;

@property (nonatomic, readonly) NSURL *ubiquityURL;
@property (nonatomic, readonly) id currentUbiquityToken;

// access
+(GameController *)sharedController;

/*
 Called by the AppDelegate whenever the application becomes active.
 We use this signal to check to see if the container identifier has
 changed.
 */
- (void)applicationResumed;

/*
 Load all the various persistent stores
 - The iCloud Store / Fallback Store if iCloud is not available
 - The persistent store used to store local data
 
 Also:
 - Seed the database if desired (using the SEED #define)
 - Unique
 */
- (void)loadPersistentStores;

#pragma mark Debugging Methods
/*
 Copy the entire contents of the application's iCloud container to the Application's sandbox.
 Use this on iOS to copy the entire contents of the iCloud Continer to the application sandbox
 where they can be downloaded by Xcode.
 */
- (void)copyContainerToSandbox;

/*
 Delete the contents of the ubiquity container, this method will do a coordinated write to
 delete every file inside the Application's iCloud Container.
 */
- (void)nukeAndPave;

@end
