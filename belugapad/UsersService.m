//
//  UsersService.m
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UsersService.h"
#import "UserNodeState.h"
#import "NodePlay.h"
#import "global.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "ContentService.h"
#import "JSONKit.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "AFNetworking.h"
#import "TestFlight.h"
#import "cocos2d/Support/base64.h"
#import "NSData+GzipExtension.h"

NSString * const kUsersWSBaseURL = @"http://u.zubi.me:3000";
NSString * const kUsersWSSyncUsersPath = @"app-users/sync-users";
NSString * const kUsersWSGetUserPath = @"app-users/get-user-matching-nick-password";
NSString * const kUsersWSCheckNickAvailablePath = @"app-users/check-nick-available";


@interface UsersService()
{
@private
    FMDatabase *allUsersDatabase;
    LoggingService *loggingService;
    NSString *contentSource;
    
    AFHTTPClient *httpClient; 
    NSOperationQueue *opQueue;
    
    BOOL isSyncing;
    
    NSMutableDictionary *currentUser;
    NSString *currentUserId;
    FMDatabase *currentUserStateDatabase;
    
    BOOL processingDownloadedState;
    BOOL applyingDownloadedState;
}

-(NSMutableDictionary*)userFromCurrentRowOfResultSet:(FMResultSet*)rs;
-(void)ensureStateDbConsistency;
-(void)downloadStateForUser:(NSString*)userId;
-(void)processDownloadedState:(NSTimer*)timer;
-(void)applyDownloadedStateUpdatesForCurrentUser;
@end


@implementation UsersService

@synthesize installationUUID;

-(id)initWithProblemPipeline:(NSString*)source
           andLoggingService:(LoggingService *)ls
{
    self = [super init];
    if (self)
    {
        contentSource = source;
        loggingService = ls;
        
        isSyncing = NO;
        
        // check that we've got an all-users database
        NSFileManager *fm = [NSFileManager defaultManager];
        NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *allUsersDBPath = [libraryDir stringByAppendingPathComponent:@"all-users.db"];
        if (![fm fileExistsAtPath:allUsersDBPath])
        {
            NSString *bundledAllUsers = BUNDLE_FULL_PATH(@"/canned-dbs/all-users.db");
            [fm copyItemAtPath:bundledAllUsers toPath:allUsersDBPath error:nil];
        }
        allUsersDatabase = [[FMDatabase databaseWithPath:allUsersDBPath] retain];
        
        NSString *userStateDir = [libraryDir stringByAppendingPathComponent:@"user-state"];
        if (![fm fileExistsAtPath:userStateDir isDirectory:nil])
        {
            [fm createDirectoryAtPath:userStateDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kUsersWSBaseURL]];
        opQueue = [[[NSOperationQueue alloc] init] retain];
    }
    
    return self;
}

-(NSString*)currentUserId
{
    return currentUserId;
}

-(FMDatabase*)allUsersDatabase
{
    return allUsersDatabase;
}

-(NSDictionary*)currentUserClone
{
    // deep copy
    if (currentUser) return [[currentUser JSONData] objectFromJSONData];
    return nil;
}

-(void)setCurrentUserToUserWithId:(NSString*)urId
{
    if (urId) urId = [urId copy];
    if (currentUserId) [currentUserId release];
    currentUserId = urId;
    
    if (currentUser)
    {
        [currentUser release];
        currentUser = nil;
    }
    
    if (currentUserStateDatabase)
    {
        [currentUserStateDatabase close];
        [currentUserStateDatabase release];
        currentUserStateDatabase = nil;
    }
    
    if (urId)
    {
        TFLog(@"logged in with beluga user id: %@", urId);
        
        [allUsersDatabase open];
        FMResultSet *rs = [allUsersDatabase executeQuery:@"SELECT id, nick, password FROM users WHERE id = ?", urId];
        if ([rs next]) currentUser = [[self userFromCurrentRowOfResultSet:rs] retain];
        [allUsersDatabase close];
        
        if (![contentSource isEqualToString:@"DATABASE"]) return;
        
        [loggingService logEvent:BL_USER_LOGIN withAdditionalData:nil];
        
        NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSFileManager *fm = [NSFileManager defaultManager];
        
        // create user's pending user state directory if it doesn't yet exist
        NSString *pendingUrStateUpdatesDir = [libraryDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/pending-state-updates", urId]];
        if (![fm fileExistsAtPath:pendingUrStateUpdatesDir])
        {
            [fm createDirectoryAtPath:pendingUrStateUpdatesDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        // set currentUserStateDatabase - copy template if one doesn't exist yet
        NSString *urStateDbPath = [libraryDir stringByAppendingPathComponent:[NSString stringWithFormat:@"user-state/%@.db", urId]];
        if (![fm fileExistsAtPath:urStateDbPath isDirectory:nil])
        {
            [fm copyItemAtPath:BUNDLE_FULL_PATH(@"/canned-dbs/user-state-template.db") toPath:urStateDbPath error:nil];
        }
        currentUserStateDatabase = [[FMDatabase databaseWithPath:urStateDbPath] retain];
        
        [self ensureStateDbConsistency];
        
        [self applyDownloadedStateUpdatesForCurrentUser];
        [self downloadStateForUser:urId];
    }
}

-(void)ensureStateDbConsistency
{
    if (![contentSource isEqualToString:@"DATABASE"]) return;
    
    // make every content node has a corresponding row on the Nodes table
    [currentUserStateDatabase open];
    
    NSMutableArray *stateNodeIds = [NSMutableArray array];
    FMResultSet *rs = [currentUserStateDatabase executeQuery:@"SELECT id FROM Nodes"];
    while([rs next])
    {
        NSString *nodeId = [rs stringForColumnIndex:0];
        if (nodeId) [stateNodeIds addObject:nodeId];
    }
    
    NSArray *missingNodeIds = nil;
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    missingNodeIds = [ac.contentService conceptNodeIdsNotIn:stateNodeIds];
    
    if ([missingNodeIds count])
    {
        [currentUserStateDatabase executeUpdate:[NSString stringWithFormat:@"INSERT INTO Nodes ('id') VALUES('%@')", [missingNodeIds componentsJoinedByString:@"'),('"]]];
    }
    
    [currentUserStateDatabase close];
}

-(NSMutableArray*)deviceUsersByNickName
{    
    NSMutableArray *users = [NSMutableArray array];
    
    [allUsersDatabase open];
    FMResultSet *rs = [allUsersDatabase executeQuery:@"SELECT id, nick, password FROM users"];
    while([rs next])
        [users addObject:[self userFromCurrentRowOfResultSet:rs]];
    [rs close];
    [allUsersDatabase close];
    
    NSSortDescriptor *descriptor = [[[NSSortDescriptor alloc] initWithKey:@"nick" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)] autorelease];
    [users sortedArrayUsingDescriptors:[NSArray arrayWithObject:descriptor]];
    return users;
}

-(void)createNewUserWithNick:(NSString*)nick
                 andPassword:(NSString*)password
                    callback:(void (^)(BL_USER_CREATION_STATUS))callback
{
    // ensure no other users on device with same nick
    [allUsersDatabase open];
    FMResultSet *rs = [allUsersDatabase executeQuery:@"SELECT 1 FROM users WHERE nick = ?", nick];
    BOOL nickTaken = [rs next];
    [rs close];    
    if (nickTaken)
    {
        callback(BL_USER_CREATION_FAILURE_NICK_UNAVAILABLE);
        [allUsersDatabase close];
        return;
    }
    
    // no nick conflict on device - send create user request to server
    NSMutableURLRequest *req = [httpClient requestWithMethod:@"POST"
                                                        path:kUsersWSCheckNickAvailablePath
                                                  parameters:[NSDictionary dictionaryWithObject:nick forKey:@"nick"]];
    __block typeof(self) bself = self;    
    void (^onCompletion)() = ^(AFHTTPRequestOperation *op, id res)
    {
        BL_USER_CREATION_STATUS status = BL_USER_CREATION_SUCCESS_NICK_AVAILABILITY_UNCONFIRMED;
        
        BOOL reqSuccess = res != nil && ![res isKindOfClass:[NSError class]];
        if (reqSuccess)
        {
            NSString *resultString = [[[NSString alloc] initWithBytes:[res bytes] length:[res length] encoding:NSUTF8StringEncoding] autorelease];
            if ([@"true" isEqualToString:resultString]) status = BL_USER_CREATION_SUCCESS_NICK_AVAILABLE;
            else if ([@"false" isEqualToString:resultString]) status = BL_USER_CREATION_FAILURE_NICK_UNAVAILABLE;
        }
        
        if (BL_USER_CREATION_SUCCESS_NICK_AVAILABLE == status || BL_USER_CREATION_SUCCESS_NICK_AVAILABILITY_UNCONFIRMED == status)
        {
            CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
            CFStringRef UUIDSRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
            NSString *urId = [NSString stringWithFormat:@"%@", UUIDSRef];
            
            CFRelease(UUIDRef);
            CFRelease(UUIDSRef);
            
            FMDatabase *db = bself->allUsersDatabase;
            [db executeUpdate:@"INSERT INTO users(id,nick,password) values(?,?,?)", urId, nick, password];
        }
        callback(status);
    };
    AFHTTPRequestOperation *reqOp = [[[AFHTTPRequestOperation alloc] initWithRequest:req] autorelease];
    [reqOp setCompletionBlockWithSuccess:onCompletion failure:onCompletion];
    [opQueue addOperation:reqOp];
}

-(void)downloadUserMatchingNickName:(NSString*)nickName
                        andPassword:(NSString*)password
                           callback:(void (^)(NSDictionary*))callback
{
    NSMutableURLRequest *req = [httpClient requestWithMethod:@"POST"
                                                        path:kUsersWSGetUserPath
                                                  parameters:@{ @"nick":nickName, @"password":password }];
    
    __block typeof(self) bself = self;
    
    void (^onCompletion)() = ^(AFHTTPRequestOperation *op, id res)
    {
        BOOL reqSuccess = res != nil && ![res isKindOfClass:[NSError class]];
        
        if (!reqSuccess)
        {
            callback(nil);
            return;
        }
        
        NSString *resultString = [[NSString alloc] initWithBytes:[res bytes] length:[res length] encoding:NSUTF8StringEncoding];
        NSDictionary *user = [resultString objectFromJSONString];
        
        if (!user)
        {
            callback(nil);
            return;
        }
        
        NSString *urId = [user objectForKey:@"id"];
        
        if (!urId)
        {
            callback(nil);
            return;
        }
        
        [bself->allUsersDatabase open];
        BOOL successInsert = [bself->allUsersDatabase executeUpdate:@"INSERT INTO users(id,nick,password) values(?,?,?)", urId, nickName, password];
        [bself->allUsersDatabase close];
        
        if (!successInsert)
        {
            callback(nil);
            return;
        }
        
        callback(user);
    }; 
    
    AFHTTPRequestOperation *reqOp = [[[AFHTTPRequestOperation alloc] initWithRequest:req] autorelease];
    [reqOp setCompletionBlockWithSuccess:onCompletion failure:onCompletion];
    [opQueue addOperation:reqOp];
}

-(void)downloadStateForUser:(NSString*)userId
{
    if (![contentSource isEqualToString:@"DATABASE"]) return;
    
    
    // device id (goes in the query string)
    NSString *installationId = [[NSUserDefaults standardUserDefaults] objectForKey:@"installationUUID"];
    
    
    // in the response below, the server includes the date of the last batch that it has processed for this user on this device.
    // UsersService#applyDownloadedStateUpdatesForCurrentUser stores the date on user's row in users table / col last_server_process_batch_date
    
    // the next time this method is called (say now) we send this date back to the server
    // the server includes in the response below a list of batch ids that it has processed for this user on this device since that date
    
    // this tells UsersService#applyDownloadedStateUpdatesForCurrentUser which rows in the activity tables have been accounted for in the state database and should thus be deleted before recalculating state locally
    
    // anyway...
    [allUsersDatabase open];
    FMResultSet *rs = [allUsersDatabase executeQuery:@"SELECT last_server_process_batch_date FROM users WHERE id = ?", userId];
    if (![rs next]) return; // ERROR!
    double date = [rs intForColumnIndex:0];
    [allUsersDatabase close];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"app-users/%@/state?device=%@&last_batch_process_date=%f", userId, installationId, date] relativeToURL:[NSURL URLWithString:kUsersWSBaseURL]];
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    [req setTimeoutInterval:20.0];
    [req setHTTPMethod: @"GET"];
    [req setValue:@"application/json" forHTTPHeaderField:@"accepts"];
    
    __block typeof(self) bself = self;
    __block SEL processData = @selector(processDownloadedState:);
    
    void (^onCompletion)() = ^(AFHTTPRequestOperation *op, id res)
    {
        BOOL reqSuccess = res != nil && ![res isKindOfClass:[NSError class]] && [op.response statusCode] == 200;
        if (reqSuccess)
        {
            NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:bself selector:processData userInfo:@{ @"userId":userId, @"responseData":res } repeats:YES];
            [bself performSelector:processData withObject:timer];
        }
    };
    
    AFHTTPRequestOperation *reqOp = [[[AFHTTPRequestOperation alloc] initWithRequest:req] autorelease];
    [reqOp setCompletionBlockWithSuccess:onCompletion failure:onCompletion];
    [opQueue addOperation:reqOp];
}

-(void)processDownloadedState:(NSTimer*)timer
{
    if (processingDownloadedState || applyingDownloadedState) return;
    processingDownloadedState = YES;
    
    NSDictionary *updateInfo = [timer userInfo];
    
    NSData *data = [updateInfo valueForKey:@"responseData"];
    NSString *userId = [updateInfo valueForKey:@"userId"];
    
    NSString *jsonString = [[[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding] autorelease];
    NSDictionary *update = [jsonString objectFromJSONString];
    NSString *dateString = [update valueForKey:@"lastProcessedBatchDate"];
    double date = [dateString doubleValue];
    
    NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *pendingUrStateUpdatesDir = [libraryDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/pending-state-updates", userId]];
    
    BOOL updateOutdated = NO;
    
    // there's max 1 pending update
    NSArray *pendingUpdates = [fm contentsOfDirectoryAtPath:pendingUrStateUpdatesDir error:nil];
    if ([pendingUpdates count])
    {
        NSString *prevUpdateDateString = [pendingUpdates objectAtIndex:0];
        double prevUpdateDate = [prevUpdateDateString doubleValue];
        
        if (prevUpdateDate >= date) updateOutdated = YES; // there's an at least as up-to-date update pending application
        else [fm removeItemAtPath:[NSString stringWithFormat:@"%@/%@", pendingUrStateUpdatesDir, prevUpdateDateString] error:nil];
    }
    
    if (!updateOutdated)
    {
        [[update JSONData] writeToFile:[NSString stringWithFormat:@"%@/%@", pendingUrStateUpdatesDir, dateString] atomically:NO];
        //[[update JSONData] writeToFile:[pendingUrStateUpdatesDir stringByAppendingPathComponent:dateString] atomically:NO];
    }
    
    [timer invalidate];
    processingDownloadedState = NO;
}

-(void)applyDownloadedStateUpdatesForCurrentUser
{
    if (![contentSource isEqualToString:@"DATABASE"]) return;
    
    // in event of a wait it should be very quick. We're just waiting for the method processDownloadedState to complete
    double maxWait = 3; // secs
    NSDate *startWait = [NSDate date];
    while (processingDownloadedState && [[NSDate date] timeIntervalSinceDate:startWait] < maxWait) [NSThread sleepForTimeInterval:0.1];
    if (processingDownloadedState) return; // something's gone awry
    
    // we're go
    applyingDownloadedState = YES;
    [allUsersDatabase open];
    
    NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *pendingUrStateUpdatesDir = [libraryDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@/pending-state-updates", self.currentUserId]];
    
    // is there an update to process? (There will be max one, named with the date on which it was processed on the server)
    NSArray *pendingUpdates = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:pendingUrStateUpdatesDir error:nil];
    if (![pendingUpdates count])
    {
        // no pending updates. We're outta here.
        applyingDownloadedState = NO;
        [allUsersDatabase close];
        return;
    }
    
    // date of the pending update. Used a few times....
    NSString *dateString = [pendingUpdates objectAtIndex:0];
    double date = [dateString doubleValue];
    
    // ... first for accessing the file obv
    NSString *updateFilePath = [NSString stringWithFormat:@"%@/%@", pendingUrStateUpdatesDir, dateString];
    
    // Is the update more recent than the local database (responses could arrive out of order)
    FMResultSet *rs = [allUsersDatabase executeQuery:@"SELECT last_server_process_batch_date FROM users WHERE id = ?", self.currentUserId];
    double latestUpdateApplied = [rs next] ? [rs doubleForColumnIndex:0] : 0;
    if (latestUpdateApplied >= date)
    {
        // an at least as recent update has already been applied. Erase file & exeunt.
        [[NSFileManager defaultManager] removeItemAtPath:updateFilePath error:nil];
        applyingDownloadedState = NO;
        [allUsersDatabase close];
        return;
    }
    
    // UsersService#processDownloadedData stored update as jsonData
    NSDictionary *update = [[NSData dataWithContentsOfFile:updateFilePath] objectFromJSONData];
    
    // the gzipped base64-encoded user state db is on the json doc as a string
    NSString *b64GzippedDb = [update valueForKey:@"gzippedStateDatabase"];
    
    // decode from base64 to bytes
    unsigned char *in = (unsigned char *) [b64GzippedDb cStringUsingEncoding:NSASCIIStringEncoding];
    unsigned char *out;
    int outLength = base64Decode(in, [b64GzippedDb length], &out);
    
    // inflate the bytes
    NSData *dbData = [[NSData dataWithBytes:out length:outLength] gzipInflate];
    
    // write the database
    NSString *urStateDbPath = [libraryDir stringByAppendingPathComponent:[NSString stringWithFormat:@"user-state/%@.db", self.currentUserId]];
    [dbData writeToFile:urStateDbPath atomically:NO];
    
    // ensure there's a row for every node in the content database
    [self ensureStateDbConsistency];
    
    // update last_server_process_batch_date
    [allUsersDatabase executeUpdate:@"UPDATE Users set last_server_process_batch_date=? WHERE id=?", @(date), self.currentUserId];
    
    // delete activity table rows associated with user / batch ids
    NSArray *processedDeviceBatchIds = [update valueForKey:@"processedDeviceBatchIds"];
    if ([processedDeviceBatchIds count])
    {
        NSString *sql = [NSString stringWithFormat:@"DELETE FROM NodePlays WHERE user_id='%@' AND batch_id IN ('%@')", self.currentUserId, [processedDeviceBatchIds componentsJoinedByString:@"','"]];
        [allUsersDatabase executeUpdate:sql];
    }
    
    // update state from surviving rows in for the user in the activity tables
    NSMutableDictionary *nodesStates = [NSMutableDictionary dictionary];
    rs = [allUsersDatabase executeQuery:@"SELECT * FROM NodePlays WHERE user_id=?", self.currentUserId];
    while ([rs next])
    {
        NSString *nodeId = [rs stringForColumn:@"node_id"];
        UserNodeState *ns = [nodesStates objectForKey:nodeId];
        if (!ns)
        {
            ns = [[[UserNodeState alloc] initWithUserId:self.currentUserId nodeId:nodeId database:currentUserStateDatabase] autorelease];
            if (ns) [nodesStates setObject:ns forKey:nodeId];
        }
        if (ns) [ns updateStateFromNodePlay:[[[NodePlay alloc] initFromFMResultSet:rs] autorelease]];
    }
    for (UserNodeState* ns in [nodesStates allValues]) [ns saveState];
    
    // delete update file
    [[NSFileManager defaultManager] removeItemAtPath:updateFilePath error:nil];
    
    // job done
    applyingDownloadedState = NO;
 }

-(BOOL)hasCompletedNodeId:(NSString *)nodeId
{
    if (!currentUserId || !currentUserStateDatabase) return NO; // TODO: Error
    
    BOOL completed = NO;
    
    [currentUserStateDatabase open];
    FMResultSet *rs = [currentUserStateDatabase executeQuery:@"SELECT first_completed FROM Nodes WHERE id=?", nodeId];
    if ([rs next])
    {
        completed = [rs doubleForColumnIndex:0] > 0;
    } // TODO: else error
    
    [rs close];
    [currentUserStateDatabase close];
    
    return completed;
}

-(UserNodeState*)currentUserStateForNodeWithId:(NSString *)nodeId
{
    if (!currentUserStateDatabase || !self.currentUserId) return nil;
    return [[[UserNodeState alloc] initWithUserId:self.currentUserId nodeId:nodeId database:currentUserStateDatabase] autorelease];
}

-(NSDictionary*)currentUserAllNodesState
{
    NSMutableDictionary *nodesState = [NSMutableDictionary dictionary];
    
    if (currentUserStateDatabase && self.currentUserId)
    {
        [currentUserStateDatabase open];
        FMResultSet *rs = [currentUserStateDatabase executeQuery:@"SELECT * FROM Nodes"];
        
        while ([rs next])
        {
            UserNodeState *ns = [[[UserNodeState alloc] initWithUserId:self.currentUserId resultSet:rs database:currentUserStateDatabase] autorelease];
            [nodesState setValue:ns forKey:[rs stringForColumn:@"id"]];
        }
        
        [currentUserStateDatabase close];
    }
    
    return [NSDictionary dictionaryWithDictionary:nodesState];
}

-(void)flagRemoveUserFromDevice:(NSString*)userId
{
    [allUsersDatabase open];
    NSString *sqlStatement = [NSString stringWithFormat:@"UPDATE users SET flag_remove = 1 WHERE id = %@", userId];
    BOOL updateSuccess = [allUsersDatabase executeUpdate:sqlStatement];
    [allUsersDatabase close];
    
    if (!updateSuccess)
    {
        // log failure
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setValue:BL_APP_ERROR_TYPE_DB_OPERATION_FAILURE forKey:@"type"];
        [d setValue:CODE_LOCATION() forKey:@"codeLocation"];
        [d setValue:sqlStatement forKey:@"statement"];
        [loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
    }
    else
    {
        [loggingService logEvent:BL_APP_FLAG_REMOVE_USER withAdditionalData:[NSDictionary dictionaryWithObject:userId forKey:@"userId"]];
    }
}

-(void)syncDeviceUsers
{
    // at the mo this method serves purpose of pushing users to server when they were created on offline device.
    // It also tells server which users have been flagged for removal from device. The users are then actually removed when response is received
    // (Users that are flagged for removal are not inclded on login users list)
    
    if (isSyncing) return;
    
    NSMutableArray *users = [NSMutableArray array];
    
    // get users date from on-device db
    [allUsersDatabase open];
    FMResultSet *rs = [allUsersDatabase executeQuery:@"SELECT id, nick, password, flag_remove FROM users"];
    while([rs next]) [users addObject:@{
                          @"id":[rs stringForColumn:@"id"],
                          @"nick":[rs stringForColumn:@"nick"],
                          @"password":[rs stringForColumn:@"password"],
                          @"flagRemove":@([rs intForColumn:@"flag_remove"]) }];
    [allUsersDatabase close];
    
    if (![users count]) return;
    
    NSMutableURLRequest *req = [httpClient requestWithMethod:@"POST"
                                                        path:kUsersWSSyncUsersPath
                                                  parameters:[NSDictionary dictionaryWithObject:[users JSONString] forKey:@"users"]];
    __block typeof(self) bself = self;
    
    void (^onCompletion)() = ^(AFHTTPRequestOperation *op, id res)
    {
        BOOL reqSuccess = res != nil && ![res isKindOfClass:[NSError class]];
        
        if (reqSuccess)
        {
            NSArray *serverUsers = [(NSData*)res objectFromJSONData];
            
            [bself->allUsersDatabase open];
            for (NSDictionary *serverUr in serverUsers)
            {
                // remove users flagged for removal (getting list of these users so that we can log them)
                NSArray *usersToRemove = [[users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"flagRemove == 1"]] valueForKey:@"id"];
                if ([usersToRemove count])
                {
                    [bself->loggingService logEvent:BL_APP_REMOVE_USERS withAdditionalData:[NSDictionary dictionaryWithObject:usersToRemove forKey:@"userIds"]];
                    
                    NSString *sql = [NSString stringWithFormat:@"DELETE FROM users WEHERE id IN ('%@')", [usersToRemove componentsJoinedByString:@"','"]];
                    BOOL updateSuccess = [bself->allUsersDatabase executeUpdate:sql];
                    
                    if (!updateSuccess)
                    {
                        // log failure to remove users
                        NSMutableDictionary *d = [NSMutableDictionary dictionary];
                        [d setValue:BL_APP_ERROR_TYPE_DB_OPERATION_FAILURE forKey:@"type"];
                        [d setValue:CODE_LOCATION() forKey:@"codeLocation"];
                        [d setValue:sql forKey:@"statement"];
                        [bself->loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
                    }
                    
                    // TODO: delete from tables other than users - NodePlays, ActivityFeed, FeatureKeys
                }
            }
            [bself->allUsersDatabase close];
            bself->isSyncing = NO;
        }
    };
    AFHTTPRequestOperation *reqOp = [[[AFHTTPRequestOperation alloc] initWithRequest:req] autorelease];
    [reqOp setCompletionBlockWithSuccess:onCompletion failure:onCompletion];
    [opQueue addOperation:reqOp];
    isSyncing = YES;
}

-(NSMutableDictionary*)userFromCurrentRowOfResultSet:(FMResultSet*)rs
{
    NSMutableDictionary *user = [NSMutableDictionary dictionary];
    [user setValue:[rs stringForColumn:@"id"] forKey:@"id"];
    [user setValue:[rs stringForColumn:@"nick"] forKey:@"nickName"];
    [user setValue:[rs stringForColumn:@"password"] forKey:@"password"];
    return user;
}

-(BOOL)hasEncounteredFeatureKey:(NSString*)key
{
    BOOL ret = NO;
    
    if (currentUserStateDatabase)
    {
        [currentUserStateDatabase open];
        FMResultSet *rs = [currentUserStateDatabase executeQuery:@"SELECT 1 FROM FeatureKeys WHERE key = ?", key];
        if ([rs next]) ret = YES;
        [currentUserStateDatabase close];
    }
    
    return ret;
}

-(void)addEncounterWithFeatureKey:(NSString*)key date:(NSDate*)date
{
    NSNumber *time = @([date timeIntervalSince1970]);
    
    [loggingService logEvent:BL_USER_ENCOUNTER_FEATURE_KEY withAdditionalData:@{ @"key":key, @"date":time }];
    
    [allUsersDatabase open];
    [allUsersDatabase executeUpdate:@"INSERT INTO FeatureKeys(batch_id, user_id, key, date) VALUES(?,?,?,?)", loggingService.currentBatchId, currentUserId, key, time];
    [allUsersDatabase close];
    
    [currentUserStateDatabase open];
    FMResultSet *rs = [currentUserStateDatabase executeQuery:@"SELECT encounters FROM FeatureKeys WHERE key = ?", key];
    if ([rs next])
    {
        NSString *jsonString = [rs objectForColumnIndex:0];
        NSArray *keyEncounters;
        if (jsonString)
        {
            keyEncounters = [[jsonString objectFromJSONString] arrayByAddingObject:time];
        }
        else // shouldn't get here
        {
            keyEncounters = @[time];
        }
        [currentUserStateDatabase executeUpdate:@"UPDATE FeatureKeys SET encounters = ? WHERE key = ?", [keyEncounters JSONString], key];
    }
    else
    {
        [currentUserStateDatabase executeUpdate:@"INSERT INTO FeatureKeys(key, encounters) VALUES(?,?)", key, [@[time] JSONString]];
    }
    [currentUserStateDatabase close];
}

-(void)notifyStartingFeatureKey:(NSString*)featureKey
{
    
}

-(void)dealloc
{
    if (currentUser) [currentUser release];
    if (allUsersDatabase)
    {
        [self.allUsersDatabase close];
        [self.allUsersDatabase release];
    }
    if (currentUserStateDatabase)
    {
        [currentUserStateDatabase close];
        [currentUserStateDatabase release];
    }
    if (httpClient) [httpClient release];
    if (opQueue) [opQueue release];
    if (currentUserId) [currentUserId release];
    [super dealloc];
}

@end
