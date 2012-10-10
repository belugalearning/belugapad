//
//  UsersService.m
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UsersService.h"
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
    FMDatabase *usersDatabase;
    LoggingService *loggingService;
    NSString *contentSource;
    
    AFHTTPClient *httpClient; 
    NSOperationQueue *opQueue;
    
    BOOL isSyncing;
    
    NSMutableDictionary *currentUser;
    NSString *currentUserId;
}
-(NSMutableDictionary*)userFromCurrentRowOfResultSet:(FMResultSet*)rs;
@end


@implementation UsersService

@synthesize installationUUID;

-(NSString*)currentUserId
{
    return currentUserId;
}

-(FMDatabase*)usersDatabase
{
    return usersDatabase;
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
    if (urId)
    {
        TFLog(@"logged in with beluga user id: %@", urId);
        
        [usersDatabase open];
        FMResultSet *rs = [usersDatabase executeQuery:@"SELECT id, nick, nodes_completed FROM users WHERE id = ?", urId];
        if ([rs next]) currentUser = [[self userFromCurrentRowOfResultSet:rs] retain];
        [rs close];
        [usersDatabase close];
        [loggingService logEvent:BL_USER_LOGIN withAdditionalData:nil];
        
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
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *usersDatabasePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"users.db"];
        
        usersDatabase = [[FMDatabase databaseWithPath:usersDatabasePath] retain];
        [usersDatabase open];        
        if (![usersDatabase tableExists:@"users"]) [usersDatabase executeUpdate:@"CREATE TABLE users (id TEXT, nick TEXT, password TEXT, nodes_completed TEXT, flag_remove INTEGER)"];
        [usersDatabase close];
        
        httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:kUsersWSBaseURL]];
        opQueue = [[[NSOperationQueue alloc] init] retain];
    }
    
    return self;
}

-(NSArray*)deviceUsersByNickName
{    
    NSMutableArray *users = [NSMutableArray array];
    
    [usersDatabase open];
    FMResultSet *rs = [usersDatabase executeQuery:@"SELECT id, nick, nodes_completed FROM users ORDER BY nick"];
    while([rs next])
        [users addObject:[self userFromCurrentRowOfResultSet:rs]];
    [rs close];
    [usersDatabase close];
    return users;
}

-(void)setCurrentUserToNewUserWithNick:(NSString*)nick
                           andPassword:(NSString*)password
                              callback:(void (^)(BL_USER_CREATION_STATUS))callback
{
    // ensure no other users on device with same nick
    [usersDatabase open];
    FMResultSet *rs = [usersDatabase executeQuery:@"SELECT 1 FROM users WHERE nick = ?", nick];
    BOOL nickTaken = [rs next];
    [rs close];    
    if (nickTaken)
    {
        callback(BL_USER_CREATION_FAILURE_NICK_UNAVAILABLE);
        [usersDatabase close];
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
            
            FMDatabase *db = bself->usersDatabase;
            [db executeUpdate:@"INSERT INTO users(id,nick,password,nodes_completed) values(?,?,?,?)", urId, nick, password, @"[]"];
            
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
        NSString *nodesCompleted = [(NSArray*)[user objectForKey:@"nodesCompleted"] JSONString];
        
        if (!urId || !nodesCompleted)
        {
            callback(nil);
            return;
        }
        
        [bself->usersDatabase open];
        BOOL successInsert = [bself->usersDatabase executeUpdate:@"INSERT INTO users(id,nick,password,nodes_completed) values(?,?,?,?)", urId, nickName, password, nodesCompleted];
        [bself->usersDatabase close];
        
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

-(void)addCompletedNodeId:(NSString*)nodeId
{
    if (!currentUser)
    {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setValue:BL_APP_ERROR_TYPE_UNEXPECTED_NULL_VALUE forKey:@"type"];
        [d setValue:@"UsersService#addCompletedNodeId" forKey:@"codeLocation"];
        [d setValue:@"currentUser" forKey:@"value"];
        [loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
        return;
    }
    
    NSMutableArray *nc = [currentUser objectForKey:@"nodesCompleted"];
    [nc addObject:nodeId];
    
    [usersDatabase open];    
    BOOL updateSuccess = [usersDatabase executeUpdate:@"UPDATE users SET nodes_completed = ? WHERE id = ?", [nc JSONString], [currentUser objectForKey:@"id"]];
    [usersDatabase close];
    
    if (!updateSuccess)
    {
        // log failure
        NSString *statement = [NSString stringWithFormat:@"UPDATE users SET nodes_completed = \"%s\" WHERE id = \"%s\"", [nc JSONString], [currentUser objectForKey:@"id"]];
        
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setValue:BL_APP_ERROR_TYPE_DB_OPERATION_FAILURE forKey:@"type"];
        [d setValue:@"UsersService#addCompletedNodeId" forKey:@"codeLocation"];
        [d setValue:statement forKey:@"statement"];
        [loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
    }
}

-(BOOL)hasCompletedNodeId:(NSString *)nodeId
{
    return [[currentUser objectForKey:@"nodesCompleted"] containsObject:nodeId];
}

-(void)flagRemoveUserFromDevice:(NSString*)userId
{
    [usersDatabase open];
    NSString *sqlStatement = [NSString stringWithFormat:@"UPDATE users SET flag_remove = 1 WHERE id = ?", userId];
    BOOL updateSuccess = [usersDatabase executeUpdate:sqlStatement];
    [usersDatabase close];
    
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
    if (isSyncing) return;
    
    NSMutableArray *users = [NSMutableArray array];
    
    // get users date from on-device db
    [usersDatabase open];
    FMResultSet *rs = [usersDatabase executeQuery:@"SELECT id, nick, password, nodes_completed, flag_remove FROM users"];
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
    [usersDatabase close];
    
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
            NSArray *updates = [(NSData*)res objectFromJSONData];
            
            [bself->usersDatabase open];
            for (NSDictionary *updatedUr in updates)
            {
                NSString *urId = [updatedUr objectForKey:@"id"];
                
                FMResultSet *rs = [bself->usersDatabase executeQuery:@"SELECT id, nick, nodes_completed FROM users WHERE id = ?", urId];
                // chance user has been deleted since sync request sent
                if ([rs next])
                {
                    // possibility that user has completed node on client since request to server was made
                    NSMutableSet *ncSet = [NSSet setWithArray:[updatedUr objectForKey:@"nodesCompleted"]];
                    [ncSet addObjectsFromArray:[[rs stringForColumn:@"nodes_completed"] objectFromJSONString]];
                    
                    NSArray *nc = [ncSet allObjects];
                    
                    BOOL updateSuccess = [bself->usersDatabase executeUpdate:@"UPDATE users SET nodes_completed = ? WHERE id = ?", [nc JSONString], urId];
                    if (!updateSuccess)
                    {
                        NSString *statement = [NSString stringWithFormat:@"UPDATE users SET nodes_completed = \"%s\" WHERE id = \"%s\"", [nc JSONString], urId];                        
                        NSMutableDictionary *d = [NSMutableDictionary dictionary];
                        [d setValue:BL_APP_ERROR_TYPE_DB_OPERATION_FAILURE forKey:@"type"];
                        [d setValue:@"UsersService#addCompletedNodeId" forKey:@"codeLocation"];
                        [d setValue:statement forKey:@"statement"];
                        [bself->loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
                    }
                    
                    NSDictionary *currUr = bself->currentUser;
                    if (currUr && [[currUr objectForKey:@"id"] isEqualToString:urId])
                    {
                        NSMutableArray *ncMutable = [nc mutableCopy];
                        [currUr setValue:ncMutable forKey:@"nodesCompleted"];
                        [ncMutable release];
                    }
                }
                [rs close];
                
                // remove users flagged for removal (getting list of these users so that we can log them)
                NSArray *usersToRemove = [[users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"flagRemove == 1"]] valueForKey:@"id"];
                if ([usersToRemove count])
                {
                    [bself->loggingService logEvent:BL_APP_REMOVE_USERS withAdditionalData:[NSDictionary dictionaryWithObject:usersToRemove forKey:@"userIds"]];
                    
                    NSString *sqlStatement = [NSString stringWithFormat:@"DELETE FROM users WEHERE id IN %@", [usersToRemove componentsJoinedByString:@","]];
                    BOOL updateSuccess = [bself->usersDatabase executeUpdate:sqlStatement];
                    
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
            [bself->usersDatabase close];
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
    NSMutableArray *nodesCompleted = [[[rs stringForColumn:@"nodes_completed"] objectFromJSONString] mutableCopy];
    
    [user setValue:[rs stringForColumn:@"id"] forKey:@"id"];
    [user setValue:[rs stringForColumn:@"nick"] forKey:@"nickName"];
    [user setValue:nodesCompleted forKey:@"nodesCompleted"];
    
    [nodesCompleted release];
    return user;
}

-(void)dealloc
{
    if (currentUser) [currentUser release];
    if (usersDatabase) [usersDatabase release];
    if (httpClient) [httpClient release];
    if (opQueue) [opQueue release];
    if (currentUserId) [currentUserId release];
    [super dealloc];
}

@end
