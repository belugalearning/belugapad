//
//  UsersService.m
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UsersService.h"
#import "UserNodeState.h"
#import "global.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "ContentService.h"
#import "JSONKit.h"
#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "AFNetworking.h"
#import "TestFlight.h"

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
}

-(NSMutableDictionary*)userFromCurrentRowOfResultSet:(FMResultSet*)rs;
@end


@implementation UsersService

@synthesize installationUUID;

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
    if (currentUser)
    {
        [currentUser release];
        currentUser = nil;
    }
    if (currentUserId) [currentUserId release];
    if (currentUserStateDatabase)
    {
        [currentUserStateDatabase close];
        [currentUserStateDatabase release];
    }
    if (urId)
    {
        TFLog(@"logged in with beluga user id: %@", urId);
        
        [allUsersDatabase open];
        FMResultSet *rs = [allUsersDatabase executeQuery:@"SELECT id, nick FROM users WHERE id = ?", urId];
        if ([rs next]) currentUser = [[self userFromCurrentRowOfResultSet:rs] retain];
        [rs close];
        [allUsersDatabase close];
        [loggingService logEvent:BL_USER_LOGIN withAdditionalData:nil];
        
        // set currentUserStateDatabase - if it doesn't exist yet for 
        NSString *libraryDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *urStateDbPath = [libraryDir stringByAppendingPathComponent:[NSString stringWithFormat:@"user-state/%@.db", urId]];
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:urStateDbPath isDirectory:nil])
        {
            [fm copyItemAtPath:BUNDLE_FULL_PATH(@"/canned-dbs/user-state-template.db") toPath:urStateDbPath error:nil];
        }
        currentUserStateDatabase = [[FMDatabase databaseWithPath:urStateDbPath] retain];
        
        currentUserId=[urId copy];
    }
}

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

-(NSArray*)deviceUsersByNickName
{    
    NSMutableArray *users = [NSMutableArray array];
    
    [allUsersDatabase open];
    FMResultSet *rs = [allUsersDatabase executeQuery:@"SELECT id, nick FROM users ORDER BY nick"];
    while([rs next])
        [users addObject:[self userFromCurrentRowOfResultSet:rs]];
    [rs close];
    [allUsersDatabase close];
    return users;
}

-(void)setCurrentUserToNewUserWithNick:(NSString*)nick
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
            
            [bself setCurrentUserToUserWithId:urId];
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
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:nickName forKey:@"nick"];
    [d setObject:password forKey:@"password"];
    
    NSMutableURLRequest *req = [httpClient requestWithMethod:@"POST"
                                                        path:kUsersWSGetUserPath
                                                  parameters:d];
    
    __block typeof(self) bself = self;
    
    void (^onCompletion)() = ^(AFHTTPRequestOperation *op, id res)
    {
        BOOL reqSuccess = res != nil && ![res isKindOfClass:[NSError class]];
        
        if (!reqSuccess) {
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
    return;
    // THE FOLLOWING IS ABOUT TO BE MADE OBSOLETE WITH IMMINENT CHANGES TO USER STATE
    // TODO: Before deleting, go through the method and see what should be extracted to somewhere else ----- definitely need to move the user delete from device stuff.
    /*
    if (isSyncing) return;
    
    NSMutableArray *users = [NSMutableArray array];
    
    // get users date from on-device db
    [allUsersDatabase open];
    FMResultSet *rs = [allUsersDatabase executeQuery:@"SELECT id, nick, password, flag_remove FROM users"];
    while([rs next])
    {
        NSDictionary *user = [NSMutableDictionary dictionary];        
        [user setValue:[rs stringForColumnIndex:0] forKey:@"id"];
        [user setValue:[rs stringForColumnIndex:1] forKey:@"nick"];
        [user setValue:[rs stringForColumnIndex:2] forKey:@"password"];
        [user setValue:[[rs stringForColumnIndex:3] objectFromJSONString] forKey:@"nodesCompleted"];
        [user setValue:[rs stringForColumnIndex:4] forKey:@"flagRemove"];
        user = [user copy];
        [users addObject:user];
        [user release];
    }
    [rs close];
    [allUsersDatabase close];
    
    // if no users, no data to sync
    if (0 == [users count]) return;
    
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
                NSString *urId = [serverUr objectForKey:@"id"];
                
                FMResultSet *localUserRS = [bself->allUsersDatabase executeQuery:@"SELECT id, nick, nodes_completed FROM users WHERE id = ?", urId];
                // chance user has been deleted since sync request sent
                if ([localUserRS next])
                {
                    // possibility that user has completed node on client since request to server was made
                    // - so construct union of local and server records of nodes completed for user
                    
                    // init with server record
                    NSMutableSet *nodesCompletedUnion = [NSSet setWithArray:[serverUr objectForKey:@"nodesCompleted"]];
                    // and add local
                    [nodesCompletedUnion addObjectsFromArray:[[localUserRS stringForColumn:@"nodes_completed"] objectFromJSONString]];
                    
                    NSArray *nodesCompleted = [nodesCompletedUnion allObjects];
                    
                    BOOL updateSuccess = [bself->allUsersDatabase executeUpdate:@"UPDATE users SET nodes_completed = ? WHERE id = ?", [nodesCompleted JSONString], urId];
                    if (!updateSuccess)
                    {
                        NSString *statement = [NSString stringWithFormat:@"UPDATE users SET nodes_completed = \"%@\" WHERE id = \"%@\"", [nodesCompleted JSONString], urId];
                        NSMutableDictionary *d = [NSMutableDictionary dictionary];
                        [d setValue:BL_APP_ERROR_TYPE_DB_OPERATION_FAILURE forKey:@"type"];
                        [d setValue:@"UsersService#addCompletedNodeId" forKey:@"codeLocation"];
                        [d setValue:statement forKey:@"statement"];
                        [bself->loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
                    }
                    
                    // if this user is the current user, need to set nodes completed on the current user
                    NSDictionary *currUr = bself->currentUser;
                    if (currUr && [[currUr objectForKey:@"id"] isEqualToString:urId])
                    {
                        NSMutableArray *ncMutable = [nodesCompleted mutableCopy];
                        [currUr setValue:ncMutable forKey:@"nodesCompleted"];
                        [ncMutable release];
                    }
                }
                [localUserRS close];
                
                // remove users flagged for removal (getting list of these users so that we can log them)
                NSArray *usersToRemove = [[users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"flagRemove == 1"]] valueForKey:@"id"];
                if ([usersToRemove count])
                {
                    [bself->loggingService logEvent:BL_APP_REMOVE_USERS withAdditionalData:[NSDictionary dictionaryWithObject:usersToRemove forKey:@"userIds"]];
                    
                    NSString *sqlStatement = [NSString stringWithFormat:@"DELETE FROM users WEHERE id IN %@", [usersToRemove componentsJoinedByString:@","]];
                    BOOL updateSuccess = [bself->allUsersDatabase executeUpdate:sqlStatement];
                    
                    if (!updateSuccess)
                    {
                        // log failure to remove users
                        NSMutableDictionary *d = [NSMutableDictionary dictionary];
                        [d setValue:BL_APP_ERROR_TYPE_DB_OPERATION_FAILURE forKey:@"type"];
                        [d setValue:CODE_LOCATION() forKey:@"codeLocation"];
                        [d setValue:sqlStatement forKey:@"statement"];
                        [bself->loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
                    }
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
    //*/
}

-(NSMutableDictionary*)userFromCurrentRowOfResultSet:(FMResultSet*)rs
{
    NSMutableDictionary *user = [NSMutableDictionary dictionary];
    [user setValue:[rs stringForColumn:@"id"] forKey:@"id"];
    [user setValue:[rs stringForColumn:@"nick"] forKey:@"nickName"];
    return user;
}

-(void)onNewLogBatchWithId:(NSString*)batchId
{
    if (currentUserId)
    {
        [allUsersDatabase executeUpdate:@"INSERT INTO BatchesPendingProcessingOrApplication(batch_id, user_id, server_processed) values(?,?,0)", batchId, currentUserId];
    }
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
