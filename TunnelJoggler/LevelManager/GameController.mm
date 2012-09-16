//
//  GameController.m
//  TunnelJoggler
//
//  Created by pawel on 7/10/12.
//
//

#import <GameKit/GameKit.h>
#import "GameController.h"
#import "Level.h"
#import "Paddle.h"
#import "Game.h"
#import "SplashScene.h"
#import "LocalPlayer.h"

NSString * kPlayeriCloudPersistentStoreFilename = @"PlayeriCloudStore.sqlite";
NSString * kPlayerFallbackPersistentStoreFilename = @"PlayerFallbackStore.sqlite"; //used when iCloud is not available
NSString * kLevelsLocalStoreFilename = @"LevelsLocalStore.sqlite"; //holds local information

static int gNumberOfLevels = 30;
static NSOperationQueue *_presentedItemOperationQueue;

@interface GameController (Private)
- (BOOL)isiCloudAvailable;
- (BOOL)loadLevelsLocalPersistentStore:(NSError *__autoreleasing *)error;
- (BOOL)loadPlayerFallbackStore:(NSError * __autoreleasing *)error;
- (BOOL)loadPlayeriCloudStore:(NSError * __autoreleasing *)error;
- (void)asyncLoadPersistentStores;
- (void)dropStores;
- (void)reLoadPlayeriCloudStore:(NSPersistentStore *)store readOnly:(BOOL)readOnly;
- (BOOL)areObjectsWithNamePopulated:(NSString *) objectName inStore:(NSPersistentStore *) store;

- (void)deDupe:(NSNotification *)importNotification;

- (void)addPlayer:(Player *)player toStore:(NSPersistentStore *)store withContext:(NSManagedObjectContext *)moc;
- (void)addPlayerToStore:(NSPersistentStore *)store withContext:(NSManagedObjectContext *)moc;
- (BOOL)createLevels;
- (BOOL)createLocalPlayer;
- (BOOL)seedStore:(NSPersistentStore *)store withPersistentStoreAtURL:(NSURL *)seedStoreURL error:(NSError * __autoreleasing *)error;

- (void)copyContainerToSandbox;
- (void)nukeAndPave;
- (void)asyncNukeAndPave;

- (NSURL *)playeriCloudStoreURL;
- (NSURL *)playerFallbackStoreURL;
- (NSURL *)levelsStoreURL;
- (NSURL *)applicationSandboxStoresDirectory;
- (NSString *)applicationDocumentsDirectory;
- (void)iCloudAccountChanged:(NSNotification *)notification;

- (BOOL) retryToAddiCloudStore;
- (void) nukeAndPaveiCloudStore;


//- (NSString *) UUIDString;
- (NSManagedObject *) getRawObjectOrNilWithName: (NSString *) objectName fromStore: (NSPersistentStore *) store;
- (void) syncLocalPlayerWithPlayerFromStore: (NSPersistentStore *) store;
- (void) syncPlayerValues: (Player *) p withLocalPlayer: (LocalPlayer *) lp;
- (void) resetLocalPlayer;
@property (retain, nonatomic, readonly) LocalPlayer *localPlayer;
@end

@implementation GameController

@synthesize player;
@synthesize levels;
@synthesize psc = _psc;
@synthesize mainThreadContext = _mainThreadContext;
@synthesize playeriCloudStore = _playeriCloudStore;
@synthesize playerFallbackStore = _playerFallbackStore;
@synthesize levelsLocalStore = _levelsLocalStore;
@synthesize currentUbiquityToken = _currentUbiquityToken;
@synthesize ubiquityURL = _ubiquityURL;
@synthesize gameCenterPlayerBestScore;
@synthesize delegate;

+(GameController *)sharedController {
    static GameController *gSharedGameController = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _presentedItemOperationQueue = [[[NSOperationQueue alloc] init] autorelease];
        gSharedGameController = [[GameController alloc] init];
    });
    return gSharedGameController;
}

-(id) init {
    if((self=[super init])) {
        _loadingLock = [[NSLock alloc] init];
        _ubiquityURL = nil;
        _currentUbiquityToken = nil;
        _presentedItemURL = nil;
        _reloadStoresInProgress = NO;
        NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
        _psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
        _mainThreadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainThreadContext setPersistentStoreCoordinator:_psc];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        if ([fileManager respondsToSelector:@selector(ubiquityIdentityToken)]) {
            _currentUbiquityToken = [fileManager ubiquityIdentityToken];
            if (DEBUG_LOG) {
                NSLog(@"_currentUbiquityToken: %@", _currentUbiquityToken);
            }
        }
        
        //subscribe to the account change notification
        if ([self isiCloudAvailable]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(iCloudAccountChanged:)
                                                         name:NSUbiquityIdentityDidChangeNotification
                                                       object:nil];
        }
    }
    return self;
}

-(void)dealloc {
    [_psc release];
    [_mainThreadContext release];
    [_playeriCloudStore release];
    [_playerFallbackStore release];
    [_levelsLocalStore release];
    [super dealloc];
}

- (void) callDelegate: (SEL) selector withArg: (id) arg error: (NSError*) err
{
	assert([NSThread isMainThread]);
	if([delegate respondsToSelector: selector])
	{
		if(arg != NULL)
		{
			[delegate performSelector: selector withObject: arg withObject: err];
		}
		else
		{
			[delegate performSelector: selector withObject: err];
		}
	}
	else
	{
		NSLog(@"Missed Method");
	}
}


- (void) callDelegateOnMainThread: (SEL) selector withArg: (id) arg error: (NSError*) err
{
	dispatch_async(dispatch_get_main_queue(), ^(void)
                   {
                       [self callDelegate: selector withArg: arg error: err];
                   });
}

- (BOOL)isiCloudAvailable {
    BOOL available = NO;
    if (([[[UIDevice currentDevice] systemVersion] floatValue] >= 6.0) &&
        ([[NSFileManager defaultManager] ubiquityIdentityToken] != nil)) {
        available = YES;
    }
    return available;
}

- (void)applicationResumed {
    id token = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager respondsToSelector:@selector(ubiquityIdentityToken)]) {
        token = [fileManager ubiquityIdentityToken];
    }
    if (token != nil &&
        self.currentUbiquityToken != token) {
        if (NO == [self.currentUbiquityToken isEqual:token]) {
            [self iCloudAccountChanged:nil];
        }
    }
}

- (void)iCloudAccountChanged:(NSNotification *)notification {
    if ([self isiCloudAvailable] &&
        !_reloadStoresInProgress) {
        [[CCDirector sharedDirector] replaceScene: [SplashScene scene]];
        //tell the UI to clean up while we re-add the store
        [self dropStores];
        
        // update the current ubiquity token
        id token = [[NSFileManager defaultManager] ubiquityIdentityToken];
        _currentUbiquityToken = token;
//        LocalPlayer *lp = (LocalPlayer *)[self getRawObjectOrNilWithName: @"LocalPlayer" fromStore: _levelsLocalStore];
//        if ((nil != lp) &&
//            (NO == [self.currentUbiquityToken isEqual:token])) {
//            [self resetLocalPlayer];
//        } else {
//            [self createLocalPlayer];
//        }
        
        //reload persistent store
        [self loadPersistentStores];
    } else {
        _currentUbiquityToken = [[NSFileManager defaultManager] ubiquityIdentityToken];
    }
}

#pragma mark Managing the Persistent Stores

- (void)loadPersistentStores {
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
        BOOL locked = NO;
        @try {
            [_loadingLock lock];
            _reloadStoresInProgress = YES;
            locked = YES;
            [self asyncLoadPersistentStores];
            if (![self areObjectsWithNamePopulated:@"Level" inStore: _levelsLocalStore]) {
                [self createLevels];
            }
            if (![self areObjectsWithNamePopulated:@"LocalPlayer" inStore: _levelsLocalStore]) {
                [self createLocalPlayer];
            }
        } @finally {
            if (locked) {
                [_loadingLock unlock];
                locked = NO;
            }
            _reloadStoresInProgress = NO;
            [self callDelegateOnMainThread: @selector(persistentStoresLoaded:) withArg: NULL error: nil];
        }
    });
}

- (BOOL)loadLevelsLocalPersistentStore:(NSError *__autoreleasing *)error {
    BOOL success = YES;
    NSError *localError = nil;
    
    if (_levelsLocalStore) {
        return success;
    }
    NSURL *storeURL = [self levelsStoreURL];
    //add the store, use the "LocalConfiguration" to make sure level entities all end up in this store and that no iCloud entities end up in it
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    _levelsLocalStore = [_psc addPersistentStoreWithType:NSSQLiteStoreType
                                           configuration:@"LocalConfig"
                                                     URL:storeURL
                                                 options:options
                                                   error:&localError];
    success = (_levelsLocalStore != nil);
    if (success == NO) {
        //ruh roh
        if (localError && (error != NULL)) {
            *error = localError;
        }
    }
    
    return success;
}

- (BOOL)loadPlayerFallbackStore:(NSError * __autoreleasing *)error {
    BOOL success = YES;
    NSError *localError = nil;
    
    if (_playerFallbackStore) {
        return YES;
    }
    NSURL *storeURL = [self playerFallbackStoreURL];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    _playerFallbackStore = [_psc addPersistentStoreWithType:NSSQLiteStoreType
                                              configuration:@"CloudConfig"
                                                        URL:storeURL
                                                    options:options
                                                      error:&localError];
    success = (_playerFallbackStore != nil);
    if (NO == success) {
        if (localError  && (error != NULL)) {
            *error = localError;
        }
    }
    
    return success;
}

- (BOOL)loadPlayeriCloudStore:(NSError * __autoreleasing *)error {
    BOOL success = YES;
    NSError *localError = nil;
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    _ubiquityURL = [fm URLForUbiquityContainerIdentifier:nil];
    [fm release];
    
    NSURL *iCloudStoreURL = [self playeriCloudStoreURL];
    NSURL *iCloudDataURL = [self.ubiquityURL URLByAppendingPathComponent:@"iCloudData"];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             @"PlayeriCloudStore", NSPersistentStoreUbiquitousContentNameKey,
                             iCloudDataURL, NSPersistentStoreUbiquitousContentURLKey,
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
                             nil];
    _playeriCloudStore = [self.psc addPersistentStoreWithType:NSSQLiteStoreType
                                                configuration:@"CloudConfig"
                                                          URL:iCloudStoreURL
                                                      options:options
                                                        error:&localError];
    success = (_playeriCloudStore != nil);
    if (success) {
        //set up the file presenter
        _presentedItemURL = iCloudDataURL;
        [NSFileCoordinator addFilePresenter:self];
    } else {
        if (localError  && (error != NULL)) {
            *error = localError;
        }
    }
    
    return success;
}

- (void)asyncLoadPersistentStores {
    NSError *error = nil;
    if ([self loadLevelsLocalPersistentStore:&error]) {
        if (DEBUG_LOG) {
            NSLog(@"Added local store");
        }
    } else {
        if (DEBUG_LOG) {
            NSLog(@"Unable to add local persistent store: %@", error);
        }
    }
    
    //if iCloud is available, add the persistent store
    //if iCloud is not available, or the add call fails, fallback to local storage
    BOOL useFallbackStore = NO;
    if ([self isiCloudAvailable]) {
        if ([self loadPlayeriCloudStore:&error]) {
            if (DEBUG_LOG) {
                NSLog(@"Added iCloud Store");
            }
            
            //check to see if we need to seed data
            if (![self areObjectsWithNamePopulated:@"Player" inStore: _playeriCloudStore]) {
                //do this synchronously
                NSManagedObjectContext *addPlayerMOC = [[[NSManagedObjectContext alloc] init] autorelease];
                [addPlayerMOC setPersistentStoreCoordinator:_psc];
                [self addPlayerToStore: _playeriCloudStore withContext: addPlayerMOC];
                [self deDupe:nil];
            } else {
                [self syncLocalPlayerWithPlayerFromStore: _playeriCloudStore];
            }
            
            //check to see if we need to seed or migrate data from the fallback store
            NSFileManager *fm = [[NSFileManager alloc] init];
            if ([fm fileExistsAtPath:[[self playerFallbackStoreURL] path]]) {
                //migrate data from the fallback store to the iCloud store
                //there is no reason to do this synchronously since no other peer should have this data
                dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(globalQueue, ^{
                    NSError *blockError = nil;
                    BOOL seedSuccess = [self seedStore:_playeriCloudStore
                              withPersistentStoreAtURL:[self playerFallbackStoreURL]
                                                 error:&blockError];
                    if (seedSuccess) {
                        if (DEBUG_LOG) {
                            NSLog(@"Successfully seeded iCloud Store from Fallback Store");
                        }
                    } else {
                        if (DEBUG_LOG) {
                            NSLog(@"Error seeding iCloud Store from fallback store: %@", error);
                        }
                        abort();
                    }
                });
            }
            [fm release];
        } else {
            [self nukeAndPaveiCloudStore];
            useFallbackStore = [self retryToAddiCloudStore];
            if (DEBUG_LOG) {
                NSLog(@"Unable to add iCloud store: %@", error);
            }
        }
    } else {
        useFallbackStore = YES;
    }
    
    if (useFallbackStore) {
        if ([self loadPlayerFallbackStore:&error]) {
            if (DEBUG_LOG) {
                NSLog(@"Added fallback store: %@", self.playerFallbackStore);
            }
            //check to see if we need to seed data
            if (![self areObjectsWithNamePopulated:@"Player" inStore: _playerFallbackStore]) {
                //do this synchronously
                NSManagedObjectContext *addPlayerMOC = [[[NSManagedObjectContext alloc] init] autorelease];
                [addPlayerMOC setPersistentStoreCoordinator:_psc];
                [self addPlayerToStore: _playerFallbackStore withContext: addPlayerMOC];
            } else {
                [self syncLocalPlayerWithPlayerFromStore: _playerFallbackStore];
            }
        } else {
            if (DEBUG_LOG) {
                NSLog(@"Unable to add fallback store: %@", error);
            }
            abort();
        }
    }
}

- (NSManagedObject *) getRawObjectOrNilWithName: (NSString *) objectName fromStore: (NSPersistentStore *) store {
    NSManagedObjectContext *rawObjectMOC = [[[NSManagedObjectContext alloc] init] autorelease];
    [rawObjectMOC setPersistentStoreCoordinator:_psc];
    
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    if (store != nil) {
        [fetchRequest setAffectedStores: [NSArray arrayWithObjects:store, nil]];
    }
	NSEntityDescription *entity = [NSEntityDescription entityForName: objectName inManagedObjectContext: rawObjectMOC];
	[fetchRequest setEntity:entity];
	NSError *error = nil;
	NSArray *objects = [rawObjectMOC executeFetchRequest:fetchRequest error:&error];
	
    NSManagedObject *object = nil;
	if ([objects count] > 0) {
        object = [objects objectAtIndex: 0];
	}
    return object;
}

-(void) assignLocalPlayer:(LocalPlayer *) lp valuesFromPlayer:(Player *) p {
    lp.score = p.score;
    lp.experienceLevel = p.experienceLevel;
    lp.bonusItems = p.bonusItems;
    lp.name = p.name;
    lp.currentLevel = p.currentLevel;
}

-(void) assignPlayer:(Player*) p valuesFromLocalPlayer:(LocalPlayer*) lp {
    p.score = lp.score;
    p.experienceLevel = lp.experienceLevel;
    p.bonusItems = lp.bonusItems;
    p.name = lp.name;
    p.currentLevel = lp.currentLevel;
}

- (void) syncLocalPlayerWithPlayerFromStore: (NSPersistentStore *) store {
    LocalPlayer *lp = (LocalPlayer *)[self getRawObjectOrNilWithName: @"LocalPlayer" fromStore: _levelsLocalStore];
    Player *p = (Player *)[self getRawObjectOrNilWithName: @"Player" fromStore: store];
    
    NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] init] autorelease];
    [moc setPersistentStoreCoordinator:_psc];
    
    [self syncPlayerValues: p withLocalPlayer: lp];
    
    NSError* error = nil;
    BOOL success = [moc save:&error];
    if (!success ||
        (nil != error)) {
        if (DEBUG_LOG) {
            NSLog(@"Failed to sync LocalPlayer");
        }
    }
}

- (BOOL) seediCloudToFallback {
    BOOL seedingSuccesful = NO;
    if ([self isiCloudAvailable]) {
        NSError *error = nil;
        seedingSuccesful = [self seedStore: _playerFallbackStore withPersistentStoreAtURL: [self playeriCloudStoreURL] error: &error];
        if (error || !seedingSuccesful) {
            if (DEBUG_LOG) {
                NSLog(@"Could not seed iCloud store to Fallback store: %@", error);
            }
        } else {
            if (DEBUG_LOG) {
                NSLog(@"Successfully seeded Fallback Store from iCloud Store");
            }
        }
    }
    return seedingSuccesful;
}

- (BOOL)seedStore:(NSPersistentStore *)store withPersistentStoreAtURL:(NSURL *)seedStoreURL error:(NSError * __autoreleasing *)error {
    if (DEBUG_LOG) {
        NSLog(@"Seeding store");
    }
    BOOL success = YES;
    NSError *localError = nil;
    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
    NSPersistentStoreCoordinator *seedPSC = [[[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model] autorelease];
    NSDictionary *seedStoreOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithBool:YES], NSReadOnlyPersistentStoreOption,
                                      nil];
    NSPersistentStore *seedStore = [seedPSC addPersistentStoreWithType:NSSQLiteStoreType
                                                         configuration:nil
                                                                   URL:seedStoreURL
                                                               options:seedStoreOptions
                                                                 error:&localError];
    
    if (seedStore) {
        NSManagedObjectContext *seedMOC = [[[NSManagedObjectContext alloc] init] autorelease];
        [seedMOC setPersistentStoreCoordinator:seedPSC];
        
        //fetch all the person objects, use a batched fetch request to control memory usage
        NSFetchRequest *fr = [NSFetchRequest fetchRequestWithEntityName:@"Player"];
        NSUInteger batchSize = 5000;
        [fr setFetchBatchSize:batchSize];
        
        NSArray *players = [seedMOC executeFetchRequest:fr error:&localError];
        NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType] autorelease];
        [moc setPersistentStoreCoordinator:_psc];
        NSUInteger i = 1;
        for (Player *p in players) {
            NSLog(@"seedStore ======%d======", i);
            NSLog(@"Player experienceLevel %d", [p.experienceLevel intValue]);
            NSLog(@"Player score %d", [p.score integerValue]);
            NSLog(@"seedStore ==============");
            [self addPlayer:p toStore:store withContext:moc];
            if (0 == (i % batchSize)) {
                success = [moc save:&localError];
                if (success) {
                    /*
                     Reset the managed object context to free the memory for the inserted objects
                     The faulting array used for the fetch request will automatically free objects
                     with each batch, but inserted objects remain in the managed object context for
                     the lifecycle of the context
                     */
                    [moc reset];
                } else {
                    if (DEBUG_LOG) {
                        NSLog(@"Error saving during seed: %@", localError);
                    }
                    break;
                }
            }
            
            i++;
        }
        
        //one last save
        if ([moc hasChanges]) {
            success = [moc save:&localError];
            [moc reset];
        }
    } else {
        success = NO;
        if (DEBUG_LOG) {
            NSLog(@"Error adding seed store: %@", localError);
        }
    }
    
    if (NO == success) {
        if (localError  && (error != NULL)) {
            *error = localError;
        }
    }
    
    return success;
}

- (BOOL)areObjectsWithNamePopulated: (NSString *) objectName inStore: (NSPersistentStore *) store {
    NSManagedObjectContext *checkObjectMOC = [[[NSManagedObjectContext alloc] init] autorelease];
    [checkObjectMOC setPersistentStoreCoordinator:_psc];
    
	NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    if (store != nil) {
        [fetchRequest setAffectedStores: [NSArray arrayWithObjects:store, nil]];
    }
	NSEntityDescription *entity = [NSEntityDescription entityForName: objectName inManagedObjectContext: checkObjectMOC];
	[fetchRequest setEntity:entity];
	NSError *error = nil;
	NSArray *objects = [checkObjectMOC executeFetchRequest:fetchRequest error:&error];
	
    BOOL populated = NO;
	if ([objects count] > 0) {
		populated = YES;
	}
    return populated;
}

- (void)addPlayerToStore:(NSPersistentStore *)store withContext:(NSManagedObjectContext *)moc {
    
    LocalPlayer *lp = (LocalPlayer *)[self getRawObjectOrNilWithName: @"LocalPlayer" fromStore: _levelsLocalStore];
    
    Player *defaultPlayer = [NSEntityDescription insertNewObjectForEntityForName:@"Player" inManagedObjectContext: moc];
    if (nil != lp) {
        defaultPlayer.currentLevel = lp.currentLevel;
        defaultPlayer.name = lp.name;
        defaultPlayer.score = lp.score;
        defaultPlayer.experienceLevel = lp.experienceLevel;
        defaultPlayer.bonusItems = lp.bonusItems;
    } else {
        defaultPlayer.currentLevel = [NSNumber numberWithInt: 0];
        defaultPlayer.name = nil;
        defaultPlayer.score = [NSNumber numberWithInt: 0];
        defaultPlayer.experienceLevel = [NSNumber numberWithInt: 0];
        defaultPlayer.bonusItems = [NSNumber numberWithInt: 0];
    }
    [moc assignObject:defaultPlayer toPersistentStore:store];
    NSError *error = nil;
    BOOL success = [moc save: &error];
    if (success != YES || error != nil) {
        if (DEBUG_LOG) {
            NSLog(@"Error saving player");
        }
    }
}

- (void)addPlayer:(Player *)playerToBeAdded toStore:(NSPersistentStore *)store withContext:(NSManagedObjectContext *)moc {
    NSEntityDescription *entity = [playerToBeAdded entity];
    Player *newPlayer = [[[Player alloc] initWithEntity:entity
                         insertIntoManagedObjectContext:moc] autorelease];
    newPlayer.currentLevel = playerToBeAdded.currentLevel;
    newPlayer.name = playerToBeAdded.name;
    newPlayer.score = playerToBeAdded.score;
    newPlayer.experienceLevel = playerToBeAdded.experienceLevel;
    newPlayer.bonusItems = playerToBeAdded.bonusItems;
    [moc assignObject:newPlayer toPersistentStore:store];
}

- (void)dropStores {
    NSError *error = nil;
    
    if (_playerFallbackStore) {
        if ([_psc removePersistentStore:_playerFallbackStore error:&error]) {
            if (DEBUG_LOG) {
                NSLog(@"Removed fallback store");
            }
            _playerFallbackStore = nil;
        } else {
            if (DEBUG_LOG) {
                NSLog(@"Error removing fallback store: %@", error);
            }
        }
    }
    
    if (_playeriCloudStore) {
        _presentedItemURL = nil;
        [NSFileCoordinator removeFilePresenter:self];
        if ([_psc removePersistentStore:_playeriCloudStore error:&error]) {
            if (DEBUG_LOG) {
                NSLog(@"Removed iCloud Store");
            }
            _playeriCloudStore = nil;
        } else {
            if (DEBUG_LOG) {
                NSLog(@"Error removing iCloud Store: %@", error);
            }
        }
    }
}

-(BOOL)createLevels {
    NSManagedObjectContext *levelsMOC = [[[NSManagedObjectContext alloc] init] autorelease];
    [levelsMOC setPersistentStoreCoordinator:_psc];
    
    // length challenge 1
    Level *l1 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l1.levelNumber = [NSNumber numberWithInt: 0];
    l1.length = [NSNumber numberWithInt: 50];
    l1.mustReachEndOfLevelToPass = [NSNumber numberWithBool:YES];
    l1.timeToSurviveToPass = [NSNumber numberWithInteger:0];
    l1.scoreToPass = [NSNumber numberWithInt:0];
    l1.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/4];
    l1.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED];
    l1.speedIncreaseInterval = [NSNumber numberWithFloat:2.0f];
    l1.speedIncreaseValue = [NSNumber numberWithFloat:0.1f];
    l1.obstacleFrequency = [NSNumber numberWithFloat:1.5f];
    l1.bonusBallFrequency = [NSNumber numberWithFloat:3.0f];
    l1.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l1.haveMovingObstacles = [NSNumber numberWithBool:NO];
    l1.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l1 toPersistentStore: _levelsLocalStore];
    
    // time challenge 1
    Level *l2 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l2.levelNumber = [NSNumber numberWithInt: 1];
    l2.length = [NSNumber numberWithInt: 500];
    l2.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l2.timeToSurviveToPass = [NSNumber numberWithInteger: 30];
    l2.scoreToPass = [NSNumber numberWithInt:0];
    l2.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/4];
    l2.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED];
    l2.speedIncreaseInterval = [NSNumber numberWithFloat:2.0f];
    l2.speedIncreaseValue = [NSNumber numberWithFloat:0.1f];
    l2.obstacleFrequency = [NSNumber numberWithFloat:1.5f];
    l2.bonusBallFrequency = [NSNumber numberWithFloat:3.0f];
    l2.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l2.haveMovingObstacles = [NSNumber numberWithBool:NO];
    l2.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l2 toPersistentStore: _levelsLocalStore];
    
    // points challenge 1
    Level *l3 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l3.levelNumber = [NSNumber numberWithInt: 2];
    l3.length = [NSNumber numberWithInt: 500];
    l3.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l3.timeToSurviveToPass = [NSNumber numberWithInteger: 0];
    l3.scoreToPass = [NSNumber numberWithInt: 100];
    l3.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/4];
    l3.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED];
    l3.speedIncreaseInterval = [NSNumber numberWithFloat:2.0f];
    l3.speedIncreaseValue = [NSNumber numberWithFloat:0.1f];
    l3.obstacleFrequency = [NSNumber numberWithFloat:1.5f];
    l3.bonusBallFrequency = [NSNumber numberWithFloat:3.0f];
    l3.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l3.haveMovingObstacles = [NSNumber numberWithBool:NO];
    l3.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l3 toPersistentStore: _levelsLocalStore];
    
    // length challenge 2
    Level *l4 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l4.levelNumber = [NSNumber numberWithInt: 3];
    l4.length = [NSNumber numberWithInt: 60];
    l4.mustReachEndOfLevelToPass = [NSNumber numberWithBool:YES];
    l4.timeToSurviveToPass = [NSNumber numberWithInteger:0];
    l4.scoreToPass = [NSNumber numberWithInt:0];
    l4.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/4];
    l4.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED];
    l4.speedIncreaseInterval = [NSNumber numberWithFloat:2.0f];
    l4.speedIncreaseValue = [NSNumber numberWithFloat:0.1f];
    l4.obstacleFrequency = [NSNumber numberWithFloat:1.5f];
    l4.bonusBallFrequency = [NSNumber numberWithFloat:3.0f];
    l4.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l4.haveMovingObstacles = [NSNumber numberWithBool:NO];
    l4.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l4 toPersistentStore: _levelsLocalStore];
    
    // time challenge 2
    Level *l5 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l5.levelNumber = [NSNumber numberWithInt: 4];
    l5.length = [NSNumber numberWithInt: 500];
    l5.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l5.timeToSurviveToPass = [NSNumber numberWithInteger: 35];
    l5.scoreToPass = [NSNumber numberWithInt:0];
    l5.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/4];
    l5.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED];
    l5.speedIncreaseInterval = [NSNumber numberWithFloat:2.0f];
    l5.speedIncreaseValue = [NSNumber numberWithFloat:0.1f];
    l5.obstacleFrequency = [NSNumber numberWithFloat:1.5f];
    l5.bonusBallFrequency = [NSNumber numberWithFloat:3.0f];
    l5.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l5.haveMovingObstacles = [NSNumber numberWithBool:NO];
    l5.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l5 toPersistentStore: _levelsLocalStore];
    
    // points challenge 2
    Level *l6 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l6.levelNumber = [NSNumber numberWithInt: 5];
    l6.length = [NSNumber numberWithInt: 500];
    l6.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l6.timeToSurviveToPass = [NSNumber numberWithInteger: 0];
    l6.scoreToPass = [NSNumber numberWithInt: 200];
    l6.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/4];
    l6.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED];
    l6.speedIncreaseInterval = [NSNumber numberWithFloat:2.0f];
    l6.speedIncreaseValue = [NSNumber numberWithFloat:0.1f];
    l6.obstacleFrequency = [NSNumber numberWithFloat:1.5f];
    l6.bonusBallFrequency = [NSNumber numberWithFloat:3.0f];
    l6.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l6.haveMovingObstacles = [NSNumber numberWithBool:NO];
    l6.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l6 toPersistentStore: _levelsLocalStore];

    
    // length challenge 3
    Level *l7 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l7.levelNumber = [NSNumber numberWithInt: 6];
    l7.length = [NSNumber numberWithInt: 70];
    l7.mustReachEndOfLevelToPass = [NSNumber numberWithBool:YES];
    l7.timeToSurviveToPass = [NSNumber numberWithInteger:0];
    l7.scoreToPass = [NSNumber numberWithInt:0];
    l7.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/3];
    l7.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED];
    l7.speedIncreaseInterval = [NSNumber numberWithFloat:1.5f];
    l7.speedIncreaseValue = [NSNumber numberWithFloat:0.2f];
    l7.obstacleFrequency = [NSNumber numberWithFloat:1.5f];
    l7.bonusBallFrequency = [NSNumber numberWithFloat:3.0f];
    l7.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l7.haveMovingObstacles = [NSNumber numberWithBool:NO];
    l7.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l7 toPersistentStore: _levelsLocalStore];
    
    // time challenge 3
    Level *l8 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l8.levelNumber = [NSNumber numberWithInt: 7];
    l8.length = [NSNumber numberWithInt: 500];
    l8.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l8.timeToSurviveToPass = [NSNumber numberWithInteger: 40];
    l8.scoreToPass = [NSNumber numberWithInt:0];
    l8.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/3];
    l8.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED];
    l8.speedIncreaseInterval = [NSNumber numberWithFloat:1.5f];
    l8.speedIncreaseValue = [NSNumber numberWithFloat:0.2f];
    l8.obstacleFrequency = [NSNumber numberWithFloat:1.5f];
    l8.bonusBallFrequency = [NSNumber numberWithFloat:3.0f];
    l8.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l8.haveMovingObstacles = [NSNumber numberWithBool:NO];
    l8.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l8 toPersistentStore: _levelsLocalStore];
    
    // points challenge 3
    Level *l9 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l9.levelNumber = [NSNumber numberWithInt: 8];
    l9.length = [NSNumber numberWithInt: 500];
    l9.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l9.timeToSurviveToPass = [NSNumber numberWithInteger: 0];
    l9.scoreToPass = [NSNumber numberWithInt: 300];
    l9.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/3];
    l9.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED];
    l9.speedIncreaseInterval = [NSNumber numberWithFloat:1.5f];
    l9.speedIncreaseValue = [NSNumber numberWithFloat:0.2f];
    l9.obstacleFrequency = [NSNumber numberWithFloat:1.5f];
    l9.bonusBallFrequency = [NSNumber numberWithFloat:3.0f];
    l9.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l9.haveMovingObstacles = [NSNumber numberWithBool:NO];
    l9.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l9 toPersistentStore: _levelsLocalStore];
    
    // length challenge 4
    Level *l10 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l10.levelNumber = [NSNumber numberWithInt: 9];
    l10.length = [NSNumber numberWithInt: 80];
    l10.mustReachEndOfLevelToPass = [NSNumber numberWithBool:YES];
    l10.timeToSurviveToPass = [NSNumber numberWithInteger:0];
    l10.scoreToPass = [NSNumber numberWithInt:0];
    l10.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/2.5];
    l10.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED];
    l10.speedIncreaseInterval = [NSNumber numberWithFloat:1.5f];
    l10.speedIncreaseValue = [NSNumber numberWithFloat:0.3f];
    l10.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l10.bonusBallFrequency = [NSNumber numberWithFloat:3.0f];
    l10.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l10.haveMovingObstacles = [NSNumber numberWithBool:NO];
    l10.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l10 toPersistentStore: _levelsLocalStore];
    
    // time challenge 4
    Level *l11 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l11.levelNumber = [NSNumber numberWithInt: 10];
    l11.length = [NSNumber numberWithInt: 500];
    l11.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l11.timeToSurviveToPass = [NSNumber numberWithInteger: 45];
    l11.scoreToPass = [NSNumber numberWithInt:0];
    l11.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/2.5];
    l11.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED];
    l11.speedIncreaseInterval = [NSNumber numberWithFloat:1.5f];
    l11.speedIncreaseValue = [NSNumber numberWithFloat:0.3f];
    l11.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l11.bonusBallFrequency = [NSNumber numberWithFloat:3.0f];
    l11.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l11.haveMovingObstacles = [NSNumber numberWithBool:NO];
    l11.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l11 toPersistentStore: _levelsLocalStore];
    
    // points challenge 4
    Level *l12 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l12.levelNumber = [NSNumber numberWithInt: 11];
    l12.length = [NSNumber numberWithInt: 500];
    l12.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l12.timeToSurviveToPass = [NSNumber numberWithInteger: 0];
    l12.scoreToPass = [NSNumber numberWithInt: 400];
    l12.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/2.5];
    l12.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED];
    l12.speedIncreaseInterval = [NSNumber numberWithFloat:1.5f];
    l12.speedIncreaseValue = [NSNumber numberWithFloat:0.3f];
    l12.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l12.bonusBallFrequency = [NSNumber numberWithFloat:3.0f];
    l12.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l12.haveMovingObstacles = [NSNumber numberWithBool:NO];
    l12.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l12 toPersistentStore: _levelsLocalStore];
    
    // length challenge 5
    Level *l13 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l13.levelNumber = [NSNumber numberWithInt: 12];
    l13.length = [NSNumber numberWithInt: 90];
    l13.mustReachEndOfLevelToPass = [NSNumber numberWithBool:YES];
    l13.timeToSurviveToPass = [NSNumber numberWithInteger:0];
    l13.scoreToPass = [NSNumber numberWithInt:0];
    l13.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/2];
    l13.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*2];
    l13.speedIncreaseInterval = [NSNumber numberWithFloat:1.0f];
    l13.speedIncreaseValue = [NSNumber numberWithFloat:0.5f];
    l13.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l13.bonusBallFrequency = [NSNumber numberWithFloat:2.0f];
    l13.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l13.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l13.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l13 toPersistentStore: _levelsLocalStore];
    
    // time challenge 5
    Level *l14 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l14.levelNumber = [NSNumber numberWithInt: 13];
    l14.length = [NSNumber numberWithInt: 500];
    l14.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l14.timeToSurviveToPass = [NSNumber numberWithInteger: 50];
    l14.scoreToPass = [NSNumber numberWithInt:0];
    l14.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/2];
    l14.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*2];
    l14.speedIncreaseInterval = [NSNumber numberWithFloat:1.0f];
    l14.speedIncreaseValue = [NSNumber numberWithFloat:0.5f];
    l14.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l14.bonusBallFrequency = [NSNumber numberWithFloat:2.0f];
    l14.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l14.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l14.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l14 toPersistentStore: _levelsLocalStore];
    
    // points challenge 5
    Level *l15 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l15.levelNumber = [NSNumber numberWithInt: 14];
    l15.length = [NSNumber numberWithInt: 500];
    l15.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l15.timeToSurviveToPass = [NSNumber numberWithInteger: 0];
    l15.scoreToPass = [NSNumber numberWithInt: 500];
    l15.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/2];
    l15.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*2];
    l15.speedIncreaseInterval = [NSNumber numberWithFloat:1.0f];
    l15.speedIncreaseValue = [NSNumber numberWithFloat:0.5f];
    l15.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l15.bonusBallFrequency = [NSNumber numberWithFloat:2.0f];
    l15.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l15.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l15.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l15 toPersistentStore: _levelsLocalStore];
    
    // length challenge 6
    Level *l16 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l16.levelNumber = [NSNumber numberWithInt: 15];
    l16.length = [NSNumber numberWithInt: 100];
    l16.mustReachEndOfLevelToPass = [NSNumber numberWithBool:YES];
    l16.timeToSurviveToPass = [NSNumber numberWithInteger:0];
    l16.scoreToPass = [NSNumber numberWithInt:0];
    l16.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/1.5];
    l16.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*2];
    l16.speedIncreaseInterval = [NSNumber numberWithFloat:1.0f];
    l16.speedIncreaseValue = [NSNumber numberWithFloat:0.5f];
    l16.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l16.bonusBallFrequency = [NSNumber numberWithFloat:2.0f];
    l16.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l16.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l16.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l16 toPersistentStore: _levelsLocalStore];
    
    // time challenge 6
    Level *l17 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l17.levelNumber = [NSNumber numberWithInt: 16];
    l17.length = [NSNumber numberWithInt: 1000];
    l17.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l17.timeToSurviveToPass = [NSNumber numberWithInteger: 60];
    l17.scoreToPass = [NSNumber numberWithInt:0];
    l17.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/2];
    l17.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*2];
    l17.speedIncreaseInterval = [NSNumber numberWithFloat:1.0f];
    l17.speedIncreaseValue = [NSNumber numberWithFloat:0.5f];
    l17.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l17.bonusBallFrequency = [NSNumber numberWithFloat:2.0f];
    l17.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l17.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l17.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l17 toPersistentStore: _levelsLocalStore];
    
    // points challenge 6
    Level *l18 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l18.levelNumber = [NSNumber numberWithInt: 17];
    l18.length = [NSNumber numberWithInt: 1000];
    l18.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l18.timeToSurviveToPass = [NSNumber numberWithInteger: 0];
    l18.scoreToPass = [NSNumber numberWithInt: 600];
    l18.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/2];
    l18.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*2];
    l18.speedIncreaseInterval = [NSNumber numberWithFloat:1.0f];
    l18.speedIncreaseValue = [NSNumber numberWithFloat:0.5f];
    l18.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l18.bonusBallFrequency = [NSNumber numberWithFloat:2.0f];
    l18.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l18.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l18.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l18 toPersistentStore: _levelsLocalStore];

    // length challenge 7
    Level *l19 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l19.levelNumber = [NSNumber numberWithInt: 18];
    l19.length = [NSNumber numberWithInt: 110];
    l19.mustReachEndOfLevelToPass = [NSNumber numberWithBool:YES];
    l19.timeToSurviveToPass = [NSNumber numberWithInteger:0];
    l19.scoreToPass = [NSNumber numberWithInt:0];
    l19.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/1.4];
    l19.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*3];
    l19.speedIncreaseInterval = [NSNumber numberWithFloat:0.75f];
    l19.speedIncreaseValue = [NSNumber numberWithFloat:0.5f];
    l19.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l19.bonusBallFrequency = [NSNumber numberWithFloat:2.0f];
    l19.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l19.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l19.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l19 toPersistentStore: _levelsLocalStore];
    
    // time challenge 7
    Level *l20 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l20.levelNumber = [NSNumber numberWithInt: 19];
    l20.length = [NSNumber numberWithInt: 1000];
    l20.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l20.timeToSurviveToPass = [NSNumber numberWithInteger: 75];
    l20.scoreToPass = [NSNumber numberWithInt:0];
    l20.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/1.4];
    l20.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*3];
    l20.speedIncreaseInterval = [NSNumber numberWithFloat:0.75f];
    l20.speedIncreaseValue = [NSNumber numberWithFloat:0.5f];
    l20.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l20.bonusBallFrequency = [NSNumber numberWithFloat:2.0f];
    l20.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l20.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l20.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l20 toPersistentStore: _levelsLocalStore];
    
    // points challenge 7
    Level *l21 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l21.levelNumber = [NSNumber numberWithInt: 20];
    l21.length = [NSNumber numberWithInt: 1000];
    l21.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l21.timeToSurviveToPass = [NSNumber numberWithInteger: 0];
    l21.scoreToPass = [NSNumber numberWithInt: 700];
    l21.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/1.4];
    l21.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*3];
    l21.speedIncreaseInterval = [NSNumber numberWithFloat:0.75f];
    l21.speedIncreaseValue = [NSNumber numberWithFloat:0.5f];
    l21.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l21.bonusBallFrequency = [NSNumber numberWithFloat:2.0f];
    l21.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l21.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l21.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l21 toPersistentStore: _levelsLocalStore];

    // length challenge 8
    Level *l22 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l22.levelNumber = [NSNumber numberWithInt: 21];
    l22.length = [NSNumber numberWithInt: 120];
    l22.mustReachEndOfLevelToPass = [NSNumber numberWithBool:YES];
    l22.timeToSurviveToPass = [NSNumber numberWithInteger:0];
    l22.scoreToPass = [NSNumber numberWithInt:0];
    l22.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/1.25];
    l22.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*3];
    l22.speedIncreaseInterval = [NSNumber numberWithFloat:0.75f];
    l22.speedIncreaseValue = [NSNumber numberWithFloat:0.6f];
    l22.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l22.bonusBallFrequency = [NSNumber numberWithFloat:2.0f];
    l22.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l22.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l22.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l22 toPersistentStore: _levelsLocalStore];
    
    // time challenge 8
    Level *l23 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l23.levelNumber = [NSNumber numberWithInt: 22];
    l23.length = [NSNumber numberWithInt: 1000];
    l23.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l23.timeToSurviveToPass = [NSNumber numberWithInteger: 90];
    l23.scoreToPass = [NSNumber numberWithInt:0];
    l23.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/1.25];
    l23.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*3];
    l23.speedIncreaseInterval = [NSNumber numberWithFloat:0.75f];
    l23.speedIncreaseValue = [NSNumber numberWithFloat:0.6f];
    l23.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l23.bonusBallFrequency = [NSNumber numberWithFloat:2.0f];
    l23.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l23.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l23.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l23 toPersistentStore: _levelsLocalStore];
    
    // points challenge 8
    Level *l24 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l24.levelNumber = [NSNumber numberWithInt: 23];
    l24.length = [NSNumber numberWithInt: 1000];
    l24.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l24.timeToSurviveToPass = [NSNumber numberWithInteger: 0];
    l24.scoreToPass = [NSNumber numberWithInt: 800];
    l24.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/1.25];
    l24.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*3];
    l24.speedIncreaseInterval = [NSNumber numberWithFloat:0.75f];
    l24.speedIncreaseValue = [NSNumber numberWithFloat:0.6f];
    l24.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l24.bonusBallFrequency = [NSNumber numberWithFloat:2.0f];
    l24.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l24.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l24.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l24 toPersistentStore: _levelsLocalStore];
    
    // length challenge 9
    Level *l25 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l25.levelNumber = [NSNumber numberWithInt: 24];
    l25.length = [NSNumber numberWithInt: 130];
    l25.mustReachEndOfLevelToPass = [NSNumber numberWithBool:YES];
    l25.timeToSurviveToPass = [NSNumber numberWithInteger:0];
    l25.scoreToPass = [NSNumber numberWithInt:0];
    l25.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/1.1];
    l25.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*3];
    l25.speedIncreaseInterval = [NSNumber numberWithFloat:0.5f];
    l25.speedIncreaseValue = [NSNumber numberWithFloat:0.7f];
    l25.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l25.bonusBallFrequency = [NSNumber numberWithFloat:1.0f];
    l25.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l25.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l25.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l25 toPersistentStore: _levelsLocalStore];
    
    // time challenge 9
    Level *l26 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l26.levelNumber = [NSNumber numberWithInt: 25];
    l26.length = [NSNumber numberWithInt: 1000];
    l26.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l26.timeToSurviveToPass = [NSNumber numberWithInteger: 105];
    l26.scoreToPass = [NSNumber numberWithInt:0];
    l26.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/1.1];
    l26.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*3];
    l26.speedIncreaseInterval = [NSNumber numberWithFloat:0.5f];
    l26.speedIncreaseValue = [NSNumber numberWithFloat:0.7f];
    l26.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l26.bonusBallFrequency = [NSNumber numberWithFloat:1.0f];
    l26.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l26.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l26.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l26 toPersistentStore: _levelsLocalStore];
    
    // points challenge 9
    Level *l27 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l27.levelNumber = [NSNumber numberWithInt: 26];
    l27.length = [NSNumber numberWithInt: 1000];
    l27.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l27.timeToSurviveToPass = [NSNumber numberWithInteger: 0];
    l27.scoreToPass = [NSNumber numberWithInt: 900];
    l27.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED/1.1];
    l27.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*3];
    l27.speedIncreaseInterval = [NSNumber numberWithFloat:0.5f];
    l27.speedIncreaseValue = [NSNumber numberWithFloat:0.7f];
    l27.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l27.bonusBallFrequency = [NSNumber numberWithFloat:1.0f];
    l27.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l27.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l27.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l27 toPersistentStore: _levelsLocalStore];
    
    // length challenge 10
    Level *l28 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l28.levelNumber = [NSNumber numberWithInt: 27];
    l28.length = [NSNumber numberWithInt: 150];
    l28.mustReachEndOfLevelToPass = [NSNumber numberWithBool:YES];
    l28.timeToSurviveToPass = [NSNumber numberWithInteger:0];
    l28.scoreToPass = [NSNumber numberWithInt:0];
    l28.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED];
    l28.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*3];
    l28.speedIncreaseInterval = [NSNumber numberWithFloat:0.25f];
    l28.speedIncreaseValue = [NSNumber numberWithFloat:1.0f];
    l28.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l28.bonusBallFrequency = [NSNumber numberWithFloat:1.0f];
    l28.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l28.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l28.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l28 toPersistentStore: _levelsLocalStore];
    
    // time challenge 10
    Level *l29 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l29.levelNumber = [NSNumber numberWithInt: 28];
    l29.length = [NSNumber numberWithInt: 1000];
    l29.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l29.timeToSurviveToPass = [NSNumber numberWithInteger: 120];
    l29.scoreToPass = [NSNumber numberWithInt:0];
    l29.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED];
    l29.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*3];
    l29.speedIncreaseInterval = [NSNumber numberWithFloat:0.25f];
    l29.speedIncreaseValue = [NSNumber numberWithFloat:1.0f];
    l29.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l29.bonusBallFrequency = [NSNumber numberWithFloat:1.0f];
    l29.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l29.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l29.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l29 toPersistentStore: _levelsLocalStore];
    
    // points challenge 10
    Level *l30 = [NSEntityDescription insertNewObjectForEntityForName:@"Level" inManagedObjectContext: levelsMOC];
    l30.levelNumber = [NSNumber numberWithInt: 29];
    l30.length = [NSNumber numberWithInt: 1000];
    l30.mustReachEndOfLevelToPass = [NSNumber numberWithBool:NO];
    l30.timeToSurviveToPass = [NSNumber numberWithInteger: 0];
    l30.scoreToPass = [NSNumber numberWithInt: 1000];
    l30.maxSpeed = [NSNumber numberWithFloat:MAX_PADDLE_SPEED];
    l30.minSpeed = [NSNumber numberWithFloat:MIN_PADDLE_SPEED*3];
    l30.speedIncreaseInterval = [NSNumber numberWithFloat:0.25f];
    l30.speedIncreaseValue = [NSNumber numberWithFloat:1.0f];
    l30.obstacleFrequency = [NSNumber numberWithFloat:1.0f];
    l30.bonusBallFrequency = [NSNumber numberWithFloat:1.0f];
    l30.bonusItemFrequency = [NSNumber numberWithFloat:0.0f];
    l30.haveMovingObstacles = [NSNumber numberWithBool:YES];
    l30.isBossLevel = [NSNumber numberWithBool:NO];
    
    [levelsMOC assignObject:l30 toPersistentStore: _levelsLocalStore];
    
    NSError *createLevelsError = nil;
    BOOL success = [levelsMOC save: &createLevelsError];
    if (createLevelsError != nil) {
        if (DEBUG_LOG) {
            NSLog(@"Error creating levels.");
        }
    }
    [levelsMOC reset];
    return success;
}

-(BOOL)createLocalPlayer {
    NSManagedObjectContext *localMOC = [[[NSManagedObjectContext alloc] init] autorelease];
    [localMOC setPersistentStoreCoordinator:_psc];
    LocalPlayer *lp = [NSEntityDescription insertNewObjectForEntityForName:@"LocalPlayer" inManagedObjectContext: localMOC];;
    lp.currentLevel = [NSNumber numberWithInt: 0];
    lp.name = nil;
    lp.score = [NSNumber numberWithInt: 0];
    lp.experienceLevel = [NSNumber numberWithInt: 0];
    lp.bonusItems = [NSNumber numberWithInt: 0];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager respondsToSelector:@selector(ubiquityIdentityToken)]) {
        lp.token = [NSString stringWithFormat:@"%@", [fileManager ubiquityIdentityToken]];
    } else {
        lp.token = @"";
    }

    [localMOC assignObject:lp toPersistentStore: _levelsLocalStore];
    
    NSError *createLocalPlayerError = nil;
    BOOL success = [localMOC save: &createLocalPlayerError];
    if (createLocalPlayerError != nil) {
        if (DEBUG_LOG) {
            NSLog(@"Error creating levels.");
        }
    }
    [localMOC reset];
    return success;
}

-(void)resetLocalPlayer {
    NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] init] autorelease];
    [moc setPersistentStoreCoordinator:_psc];
    
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    [fetchRequest setAffectedStores: [NSArray arrayWithObjects:_levelsLocalStore, nil]];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"LocalPlayer" inManagedObjectContext: moc];
    [fetchRequest setEntity:entity];
    NSError *error = nil;
    NSArray *objects = [moc executeFetchRequest:fetchRequest error:&error];
    
    LocalPlayer *lp = nil;
    if ([objects count] > 0) {
        lp = [objects objectAtIndex: 0];
        lp.currentLevel = [NSNumber numberWithInt: 0];
        lp.name = nil;
        lp.score = [NSNumber numberWithInt: 0];
        lp.experienceLevel = [NSNumber numberWithInt: 0];
        lp.bonusItems = [NSNumber numberWithInt: 0];
        lp.token = [NSString stringWithFormat:@"%@", [[NSFileManager defaultManager] ubiquityIdentityToken]];
        NSError *saveError = nil;
        BOOL success = [moc save: &saveError];
        if (!success ||
            saveError != nil) {
            if (DEBUG_LOG) {
                NSLog(@"Could not reset local player.");
            }
        }
    } else {
        if (DEBUG_LOG) {
            NSLog(@"No local player to reset.");
        }
    }
}

#pragma mark -
#pragma mark Misc.

- (NSURL *)applicationSandboxStoresDirectory {
    NSURL *storesDirectory = [NSURL fileURLWithPath:[self applicationDocumentsDirectory]];
    storesDirectory = [storesDirectory URLByAppendingPathComponent:@"TunnelJugglerCloudStores"];
    
    NSFileManager *fm = [[NSFileManager alloc] init];
    if (NO == [fm fileExistsAtPath:[storesDirectory path]]) {
        //create it
        NSError *error = nil;
        BOOL createSuccess = [fm createDirectoryAtURL:storesDirectory
                          withIntermediateDirectories:YES
                                           attributes:nil
                                                error:&error];
        if (createSuccess == NO) {
            if (DEBUG_LOG) {
                NSLog(@"Unable to create application sandbox stores directory: %@\n\tError: %@", storesDirectory, error);
            }
        }
    }
    [fm release];
    return storesDirectory;
}

- (NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

- (NSString *)folderForUbiquityToken:(id)token {
    NSURL *tokenURL = [[self applicationSandboxStoresDirectory] URLByAppendingPathComponent:@"TokenFoldersData"];
    NSData *tokenData = [NSData dataWithContentsOfURL:tokenURL];
    NSMutableDictionary *foldersByToken = nil;
    if (tokenData) {
        foldersByToken = [NSKeyedUnarchiver unarchiveObjectWithData:tokenData];
    } else {
        foldersByToken = [NSMutableDictionary dictionary];
    }
    NSString *storeDirectoryUUID = [foldersByToken objectForKey:token];
    if (storeDirectoryUUID == nil) {
        NSUUID *uuid = [[[NSUUID alloc] init] autorelease];
        storeDirectoryUUID = [uuid UUIDString];
        [foldersByToken setObject:storeDirectoryUUID forKey:token];
        tokenData = [NSKeyedArchiver archivedDataWithRootObject:foldersByToken];
        [tokenData writeToFile:[tokenURL path] atomically:YES];
    }
    return storeDirectoryUUID;
}

- (NSURL *)playeriCloudStoreURL {
    NSURL *iCloudStoreURL = [self applicationSandboxStoresDirectory];
    NSAssert1(self.currentUbiquityToken, @"No ubiquity token? Why you no use fallback store? %@", self);
    
    NSString *storeDirectoryUUID = [self folderForUbiquityToken:self.currentUbiquityToken];
    
    iCloudStoreURL = [iCloudStoreURL URLByAppendingPathComponent:storeDirectoryUUID];
    NSFileManager *fm = [[NSFileManager alloc] init];
    if (NO == [fm fileExistsAtPath:[iCloudStoreURL path]]) {
        NSError *error = nil;
        BOOL createSuccess = [fm createDirectoryAtURL:iCloudStoreURL withIntermediateDirectories:YES attributes:nil error:&error];
        if (NO == createSuccess) {
            if (DEBUG_LOG) {
                NSLog(@"Unable to create iCloud store directory: %@", error);
            }
        }
    }
    [fm release];
    iCloudStoreURL = [iCloudStoreURL URLByAppendingPathComponent:kPlayeriCloudPersistentStoreFilename];
    return iCloudStoreURL;
}

- (NSURL *)playerFallbackStoreURL {
    NSString *storeURL = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:kPlayerFallbackPersistentStoreFilename];
    return [NSURL fileURLWithPath:storeURL];
}

- (NSURL *)levelsStoreURL {
    NSString *storeURL = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:kLevelsLocalStoreFilename];
    return [NSURL fileURLWithPath:storeURL];
}

//- (NSString *) UUIDString {
//    NSString *uuid = nil;
//    CFUUIDRef theUUID = CFUUIDCreate(kCFAllocatorDefault);
//    if (theUUID) {
//        uuid = NSMakeCollectable(CFUUIDCreateString(kCFAllocatorDefault, theUUID));
//        [uuid autorelease];
//        CFRelease(theUUID);
//    }
//    return uuid;
//}

#pragma mark -
#pragma mark Application Lifecycle - Uniquing
- (void)deDupe:(NSNotification *)importNotification {
    //if importNotification, scope dedupe by inserted records
    //else no search scope, prey for efficiency.
    NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
    
    NSError *error = nil;
    NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] init] autorelease];
    [moc setPersistentStoreCoordinator:_psc];
    
    NSFetchRequest *fr = [[[NSFetchRequest alloc] initWithEntityName:@"Player"] autorelease];
    [fr setIncludesPendingChanges:NO]; //distinct has to go down to the db, not implemented for in memory filtering
    [fr setFetchBatchSize:1000]; //protect the memory
    
    NSUInteger batchSize = 500; //can be set 100-10000 objects depending on individual object size and available device memory
    NSArray *dupes = [moc executeFetchRequest:fr error:&error];
    
    Player *prevPlayer = nil;
    
    NSUInteger i = 1;
    for (Player *p in dupes) {
        if (DEBUG_LOG) {
            NSLog(@"deDupe ======%d======", i);
            NSLog(@"Player experienceLevel %d", [p.experienceLevel intValue]);
            NSLog(@"Player score %d", [p.score integerValue]);
            NSLog(@"deDupe ==============");
        }
        if (prevPlayer) {
            if ([p.experienceLevel intValue] < [prevPlayer.experienceLevel intValue]) {
                [moc deleteObject:p];
            } else if ([p.experienceLevel intValue] == [prevPlayer.experienceLevel intValue]) {
                if ([p.score integerValue] < [prevPlayer.score integerValue]) {
                    [moc deleteObject:p];
                } else {
                    [moc deleteObject:prevPlayer];
                    prevPlayer = p;
                }
            } else {
                [moc deleteObject:prevPlayer];
                prevPlayer = p;
            }
        } else {
            prevPlayer = p;
        }
        
        if (0 == (i % batchSize)) {
            //save the changes after each batch, this helps control memory pressure by turning previously examined objects back in to faults
            if ([moc save:&error]) {
                if (DEBUG_LOG) {
                    NSLog(@"Saved successfully after uniquing");
                }
            } else {
                if (DEBUG_LOG) {
                    NSLog(@"Error saving unique results: %@", error);
                }
            }
        }
        
        i++;
    }
    
    if ([moc save:&error]) {
        if (DEBUG_LOG) {
            NSLog(@"Saved successfully after uniquing");
        }
    } else {
        if (DEBUG_LOG) {
            NSLog(@"Error saving unique results: %@", error);
        }
    }
    [autoreleasepool release];
}

#pragma mark Managing the Game Data

-(NSArray *)levels {
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    if (_levelsLocalStore != nil) {
        [fetchRequest setAffectedStores: [NSArray arrayWithObjects:_levelsLocalStore, nil]];
    }
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"Level" inManagedObjectContext: _mainThreadContext];
    [fetchRequest setEntity:entity];
    NSSortDescriptor *sortOrder = [[[NSSortDescriptor alloc] initWithKey:@"levelNumber" ascending: YES] autorelease];
    [fetchRequest setSortDescriptors: [NSArray arrayWithObjects:sortOrder, nil]];
    NSError *error = nil;
    NSArray *fetchedLevel = [_mainThreadContext executeFetchRequest:fetchRequest error:&error];
    if ([fetchedLevel count] > gNumberOfLevels) {
        if (DEBUG_LOG) {
            NSLog(@"WARNING: Expected %d level(s), but fetched %d", gNumberOfLevels, [fetchedLevel count]);
        }
    }
    return fetchedLevel;
}

- (LocalPlayer*)localPlayer {
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"LocalPlayer" inManagedObjectContext: _mainThreadContext];
    [fetchRequest setEntity:entity];
    NSError *error = nil;
    NSArray *fetchedLocalPlayers = [_mainThreadContext executeFetchRequest:fetchRequest error:&error];
    if ([fetchedLocalPlayers count] > 1) {
        if (DEBUG_LOG) {
            NSLog(@"WARNING: Expected only one local player, but has %d", [fetchedLocalPlayers count]);
            int index = 0;
            for (LocalPlayer *lp in fetchedLocalPlayers) {
                NSLog(@"======%d======", index);
                NSLog(@"LocalPlayer experienceLevel %d", [lp.experienceLevel intValue]);
                NSLog(@"LocalPlayer score %d", [lp.score integerValue]);
                NSLog(@"==============");
                index++;
            }
        }
    }
    LocalPlayer *resultLocalPlayer = nil;
    if ([fetchedLocalPlayers count] > 0) {
        resultLocalPlayer = [fetchedLocalPlayers objectAtIndex: 0];
        [_mainThreadContext refreshObject: resultLocalPlayer mergeChanges: YES];
        if (DEBUG_LOG && (resultLocalPlayer != nil)) {
            NSLog(@"Current player");
            NSLog(@"==============");
            NSLog(@"Player experienceLevel %d", [resultLocalPlayer.experienceLevel intValue]);
            NSLog(@"Player score %d", [resultLocalPlayer.score integerValue]);
            NSLog(@"==============");
        }
    } else {
        NSLog(@"WARNING: Does not have any players stored");
    }
    return resultLocalPlayer;
}

- (void) syncPlayerValues: (Player *) p withLocalPlayer: (LocalPlayer *) lp {
    if ((nil != lp) &&
        (nil != p)) {
        if (DEBUG_LOG) {
            NSLog(@"Before sync");
            NSLog(@"LocalPlayer score: %d", [lp.score intValue]);
            NSLog(@"LocalPlayer expirenceLevel: %d", [lp.experienceLevel intValue]);
            NSLog(@"Player score: %d", [p.score intValue]);
            NSLog(@"Player expirenceLevel: %d", [p.experienceLevel intValue]);
        }
        if ([lp.experienceLevel intValue] > [p.experienceLevel intValue]) {
            [self assignPlayer: p valuesFromLocalPlayer: lp];
        } else if ([lp.experienceLevel intValue] == [p.experienceLevel intValue]) {
            if([lp.score intValue] > [p.score intValue]) {
                [self assignPlayer: p valuesFromLocalPlayer: lp];
            } else {
                [self assignLocalPlayer: lp valuesFromPlayer: p];
            }
        } else {
            [self assignLocalPlayer: lp valuesFromPlayer: p];
        }
        if (DEBUG_LOG) {
            NSLog(@"After sync");
            NSLog(@"LocalPlayer score: %d", [lp.score intValue]);
            NSLog(@"LocalPlayer expirenceLevel: %d", [lp.experienceLevel intValue]);
            NSLog(@"Player score: %d", [p.score intValue]);
            NSLog(@"Player expirenceLevel: %d", [p.experienceLevel intValue]);
        }
    }
}

-(Player *)player {    
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName: @"Player" inManagedObjectContext: _mainThreadContext];
    [fetchRequest setEntity:entity];
    NSError *error = nil;
    NSArray *fetchedPlayers = [_mainThreadContext executeFetchRequest:fetchRequest error:&error];
    if ([fetchedPlayers count] > 1) {
        if (DEBUG_LOG) {
            NSLog(@"WARNING: Expected only one player, but has %d", [fetchedPlayers count]);
            int index = 0;
            for (Player *p in fetchedPlayers) {
                NSLog(@"======%d======", index);
                NSLog(@"Player experienceLevel %d", [p.experienceLevel intValue]);
                NSLog(@"Player score %d", [p.score integerValue]);
                NSLog(@"==============");
                index++;
            }
        }
        // deDupe & refetch players
        [self deDupe: nil];
        fetchedPlayers = [_mainThreadContext executeFetchRequest: fetchRequest error: &error];
    }
    Player *p = nil;
    if ([fetchedPlayers count] > 0) {
        LocalPlayer *lp = self.localPlayer;
        p = [fetchedPlayers objectAtIndex: 0];
        [_mainThreadContext refreshObject: p mergeChanges: YES];
        [self syncPlayerValues: p withLocalPlayer: lp];
        if (DEBUG_LOG && (p != nil)) {
            NSLog(@"Current player");
            NSLog(@"==============");
            NSLog(@"Player experienceLevel %d", [p.experienceLevel intValue]);
            NSLog(@"Player score %d", [p.score integerValue]);
            NSLog(@"==============");
        }
    } else {
        NSLog(@"WARNING: Does not have any players stored");
    }
    return p;
}

-(void)setPlayer:(Player *)playerToBeSaved {
    // fetch local player
    LocalPlayer *lp = self.localPlayer;
    
    // transfer values to local player
    [self syncPlayerValues: playerToBeSaved withLocalPlayer: lp];
    
    // save both local and iCloud/fallback player
    if (DEBUG_LOG) {
        NSLog(@"Saving player.");
        NSLog(@"==============");
        NSLog(@"Player experienceLevel %d", [playerToBeSaved.experienceLevel intValue]);
        NSLog(@"Player score %d", [playerToBeSaved.score integerValue]);
        NSLog(@"==============");
    }
    if ([playerToBeSaved.score intValue] > self.gameCenterPlayerBestScore) {
        [[GameCenterManager sharedManager] reportScore: [playerToBeSaved.score intValue] forCategory: kTunnelJugglerLeaderboardID];
    }
    NSError *error = nil;
    BOOL success = [_mainThreadContext save: &error];
    if (error || !success) {
        if (DEBUG_LOG) {
            NSLog(@"Could not save player data.");
        }
    }
}

#pragma mark -
#pragma mark Merging Changes
+ (void)mergeiCloudChangeNotification:(NSNotification *)note withManagedObjectContext:(NSManagedObjectContext *)moc {
    [moc performBlock:^{
        [moc mergeChangesFromContextDidSaveNotification:note];
    }];
}

#pragma mark -
#pragma mark DEBUG_LOGging Helpers
- (void)copyContainerToSandbox {
    NSAutoreleasePool *autoreleasepool = [[NSAutoreleasePool alloc] init];
    
    NSError *error = nil;
    NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
    NSString *path = [self.ubiquityURL path];
    NSString *sandboxPath = [[self applicationDocumentsDirectory] stringByAppendingPathComponent:[self.ubiquityURL lastPathComponent]];
    
    if ([fm createDirectoryAtPath:sandboxPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        if (DEBUG_LOG) {
            NSLog(@"Created container directory in sandbox: %@", sandboxPath);
        }
    } else {
        if ([[error domain] isEqualToString:NSCocoaErrorDomain]) {
            if ([error code] == NSFileWriteFileExistsError) {
                //delete the existing directory
                error = nil;
                if ([fm removeItemAtPath:sandboxPath error:&error]) {
                    if (DEBUG_LOG) {
                        NSLog(@"Removed old sandbox container copy");
                    }
                } else {
                    if (DEBUG_LOG) {
                        NSLog(@"Error trying to remove old sandbox container copy: %@", error);
                    }
                }
            }
        } else {
            if (DEBUG_LOG) {
                NSLog(@"Error attempting to create sandbox container copy: %@", error);
            }
            return;
        }
    }
    
    NSArray *subPaths = [fm subpathsAtPath:path];
    for (NSString *subPath in subPaths) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, subPath];
        NSString *fullSandboxPath = [NSString stringWithFormat:@"%@/%@", sandboxPath, subPath];
        BOOL isDirectory = NO;
        if ([fm fileExistsAtPath:fullPath isDirectory:&isDirectory]) {
            if (isDirectory) {
                //create the directory
                BOOL createSuccess = [fm createDirectoryAtPath:fullSandboxPath
                                   withIntermediateDirectories:YES
                                                    attributes:nil
                                                         error:&error];
                if (createSuccess) {
                    //yay
                } else {
                    if (DEBUG_LOG) {
                        NSLog(@"Error creating directory in sandbox: %@", error);
                    }
                }
            } else {
                //simply copy the file over
                BOOL copySuccess = [fm copyItemAtPath:fullPath
                                               toPath:fullSandboxPath
                                                error:&error];
                if (copySuccess) {
                    //yay
                } else {
                    if (DEBUG_LOG) {
                        NSLog(@"Error copying item at path: %@\nTo path: %@\nError: %@", fullPath, fullSandboxPath, error);
                    }
                }
            }
        } else {
            if (DEBUG_LOG) {
                NSLog(@"Got subpath but there is no file at the full path: %@", fullPath);
            }
        }
    }
    
    [autoreleasepool release];
}

- (void)nukeAndPave {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [self asyncNukeAndPave];
    });
}

- (BOOL) retryToAddiCloudStore {
    BOOL success = NO;
    if ([self isiCloudAvailable]) {
        NSError *error = nil;
        if ([self loadPlayeriCloudStore:&error]) {
            if (DEBUG_LOG) {
                NSLog(@"Added iCloud Store");
            }
            
            //check to see if we need to seed data
            if (![self areObjectsWithNamePopulated:@"Player" inStore: _playeriCloudStore]) {
                //do this synchronously
                NSManagedObjectContext *addPlayerMOC = [[[NSManagedObjectContext alloc] init] autorelease];
                [addPlayerMOC setPersistentStoreCoordinator:_psc];
                [self addPlayerToStore: _playeriCloudStore withContext: addPlayerMOC];
                [self deDupe:nil];
            }
            
            //check to see if we need to seed or migrate data from the fallback store
            NSFileManager *fm = [[NSFileManager alloc] init];
            if ([fm fileExistsAtPath:[[self playerFallbackStoreURL] path]]) {
                //migrate data from the fallback store to the iCloud store
                //there is no reason to do this synchronously since no other peer should have this data
                dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
                dispatch_async(globalQueue, ^{
                    NSError *blockError = nil;
                    BOOL seedSuccess = [self seedStore:_playeriCloudStore
                              withPersistentStoreAtURL:[self playerFallbackStoreURL]
                                                 error:&blockError];
                    if (seedSuccess) {
                        if (DEBUG_LOG) {
                            NSLog(@"Successfully seeded iCloud Store from Fallback Store");
                        }
                    } else {
                        if (DEBUG_LOG) {
                            NSLog(@"Error seeding iCloud Store from fallback store: %@", error);
                        }
                        abort();
                    }
                });
            }
            [fm release];
            success = YES;
        }
    }
    return success;
}

- (void)nukeAndPaveiCloudStore {
    NSFileCoordinator *fc = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [self.ubiquityURL path];
    NSArray *subPaths = [fm subpathsAtPath:path];
    for (NSString *subPath in subPaths) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, subPath];
        [fc coordinateWritingItemAtURL:[NSURL fileURLWithPath:fullPath]
                               options:NSFileCoordinatorWritingForDeleting
                                 error:&error
                            byAccessor:^(NSURL *newURL) {
                                NSError *blockError = nil;
                                if ([fm removeItemAtURL:newURL error:&blockError]) {
                                    if (DEBUG_LOG) {
                                        NSLog(@"Deleted file: %@", newURL);
                                    }
                                } else {
                                    if (DEBUG_LOG) {
                                        NSLog(@"Error deleting file: %@\nError: %@", newURL, blockError);
                                    }
                                }
                                
                            }];
    }
    [fc release];
    fc = nil;

}

- (void)asyncNukeAndPave {
    //disconnect from the various stores
    [self dropStores];
    
    NSFileCoordinator *fc = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
    NSError *error = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *path = [self.ubiquityURL path];
    NSArray *subPaths = [fm subpathsAtPath:path];
    for (NSString *subPath in subPaths) {
        NSString *fullPath = [NSString stringWithFormat:@"%@/%@", path, subPath];
        [fc coordinateWritingItemAtURL:[NSURL fileURLWithPath:fullPath]
                               options:NSFileCoordinatorWritingForDeleting
                                 error:&error
                            byAccessor:^(NSURL *newURL) {
                                NSError *blockError = nil;
                                if ([fm removeItemAtURL:newURL error:&blockError]) {
                                    if (DEBUG_LOG) {
                                        NSLog(@"Deleted file: %@", newURL);
                                    }
                                } else {
                                    if (DEBUG_LOG) {
                                        NSLog(@"Error deleting file: %@\nError: %@", newURL, blockError);
                                    }
                                }
                                
                            }];
    }
    [fc release];
    fc = nil;
}

#pragma mark -
#pragma mark NSFilePresenter

- (NSURL *)presentedItemURL {
    return _presentedItemURL;
}

- (NSOperationQueue *)presentedItemOperationQueue {
    return _presentedItemOperationQueue;
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler {
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        [self iCloudAccountChanged:nil];
    });
    completionHandler(NULL);
}

#pragma mark -
#pragma mark GameCenterManagerDelegate protocol methods

- (void) processGameCenterAuth: (NSError*) error {
    
    if(error == NULL)
    {
        [[GameCenterManager sharedManager] reloadHighScoresForCategory: kTunnelJugglerLeaderboardID];
    }
    else
    {
        if (DEBUG_LOG) {
            NSLog(@"Game center authentication processed with error %@", error);
        }
        //        UIAlertView* alert= [[[UIAlertView alloc] initWithTitle: @"Game Center"
        //                                                        message: [NSString stringWithFormat: @"%@", [error localizedDescription]]
        //                                                       delegate: self cancelButtonTitle: @"Dismiss" otherButtonTitles: NULL] autorelease];
        //        [alert show];
    }
}

- (void) scoreReported: (NSError*) error {
    if (DEBUG_LOG) {
        NSLog(@"Score reported with error %@", error);
    }
}

- (void) reloadScoresComplete: (GKLeaderboard*) leaderBoard error: (NSError*) error {
    if(error == nil)
	{
		self.gameCenterPlayerBestScore = leaderBoard.localPlayerScore.value;
	}
	else
	{
        self.gameCenterPlayerBestScore = -1;
	}
    if (DEBUG_LOG) {
        NSLog(@"Game center player best score %lld", self.gameCenterPlayerBestScore);
    }
}

- (void) achievementSubmitted: (GKAchievement*) ach error:(NSError*) error {
    
}

- (void) achievementResetResult: (NSError*) error {
    
}

- (void) mappedPlayerIDToPlayer: (GKPlayer*) player error: (NSError*) error {
    if (DEBUG_LOG) {
        NSLog(@"Mapped PlayerID to Player with error %@", error);
    }
}

@end
