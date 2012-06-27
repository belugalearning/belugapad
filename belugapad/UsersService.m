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
    
    __block BOOL isSyncing;
}
-(NSDictionary*)userFromCurrentRowOfResultSet:(FMResultSet*)rs;
@end



@implementation UsersService

@synthesize installationUUID;
@synthesize currentUser;

-(void)setCurrentUser:(NSDictionary*)ur
{
    [ur retain];
    [currentUser release];
    currentUser=ur;
    
    if (ur)
    {
        [loggingService logEvent:BL_USER_LOGIN withAdditionalData:nil];
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
        if (![usersDatabase tableExists:@"users"]) [usersDatabase executeUpdate:@"CREATE TABLE users (id TEXT, nick TEXT, password TEXT, nodes_completed TEXT)"];
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

-(void) nickNameIsAvailable:(NSString*)nickName
                   callback:(void (^)(BL_USER_NICK_AVAILABILITY))callback
{
    // TODO: This only checks local database of users - needs to check with server
    [usersDatabase open];
    FMResultSet *rs = [usersDatabase executeQuery:@"SELECT 1 FROM users WHERE nick = ?", nickName];
    BOOL isAvailable = ![rs next];    
    [rs close];
    [usersDatabase close];
    
    if (!isAvailable)
    {
        callback(BL_USER_NICK_IS_UNAVAILABLE);
        return;
    }
    
    // available on device - is it available on the server?
    
    NSMutableURLRequest *req = [httpClient requestWithMethod:@"POST"
                                                        path:kUsersWSCheckNickAvailablePath
                                                  parameters:[NSDictionary dictionaryWithObject:nickName forKey:@"nick"]];
    
    void (^onCompletion)() = ^(AFHTTPRequestOperation *op, id res)
    {
        BOOL reqSuccess = res != nil && ![res isKindOfClass:[NSError class]];
        BL_USER_NICK_AVAILABILITY avail = BL_USER_NICK_AVAILABILITY_UNCONFIRMED;
        if (reqSuccess)
        {
            NSString *resultString = [[[NSString alloc] initWithBytes:[res bytes] length:[res length] encoding:NSUTF8StringEncoding] autorelease];
            if ([@"true" isEqualToString:resultString]) avail = BL_USER_NICK_IS_AVAILABLE;
            else if ([@"false" isEqualToString:resultString]) avail = BL_USER_NICK_IS_UNAVAILABLE;
        }
        callback(avail);
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
        
        [usersDatabase open];
        BOOL successInsert = [usersDatabase executeUpdate:@"INSERT INTO users(id,nick,password,nodes_completed) values(?,?,?,?)", urId, nickName, password, nodesCompleted];
        [usersDatabase close];
        
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

-(NSDictionary*) getNewUserWithNickName:(NSString*)nickName
                            andPassword:(NSString*)password
                           andZubiColor:(NSData*)color // rgba
                      andZubiScreenshot:(UIImage*)image
{
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDSRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    NSString *urId = [NSString stringWithFormat:@"%@", UUIDSRef];
    
    CFRelease(UUIDRef);
    CFRelease(UUIDSRef);
    
    [usersDatabase open];
    [usersDatabase executeUpdate:@"INSERT INTO users(id,nick,password,nodes_completed) values(?,?,?,?)", urId, nickName, password, @"[]"];
    FMResultSet *rs = [usersDatabase executeQuery:@"SELECT id, nick, nodes_completed FROM users WHERE id = ?", urId];
    [rs next];
    NSDictionary *ur = [self userFromCurrentRowOfResultSet:rs];
    [rs close];
    [usersDatabase close];
    
    return ur;
}

-(void)addCompletedNodeId:(NSString *)nodeId
{
    NSString *urId = [currentUser objectForKey:@"id"];
    NSMutableArray *nc = [[[currentUser objectForKey:@"nodesCompleted"] mutableCopy] autorelease];
    if (!nc) nc = [NSMutableArray array];
    [nc addObject:nodeId];
    
    [usersDatabase open];
    
    BOOL updateSuccess = [usersDatabase executeUpdate:@"UPDATE users SET nodes_completed = ? WHERE id = ?", [nc JSONString], urId];
    if (!updateSuccess) NSLog(@"failed to update user");
    
    FMResultSet *rs = [usersDatabase executeQuery:@"SELECT id, nick, nodes_completed FROM users WHERE id = ?", urId];
    [rs next];
    
    [currentUser release];
    currentUser = [[self userFromCurrentRowOfResultSet:rs] retain];
    
    [rs close];
    [usersDatabase close];
}

-(BOOL)hasCompletedNodeId:(NSString *)nodeId
{
    return [[currentUser objectForKey:@"nodesCompleted"] containsObject:nodeId];
}

-(void)syncDeviceUsers
{
    if (isSyncing) return;
    
    NSMutableArray *users = [NSMutableArray array];
    
    // get users date from on-device db
    [usersDatabase open];
    FMResultSet *rs = [usersDatabase executeQuery:@"SELECT id, nick, password, nodes_completed FROM users"];
    while([rs next])
    {
        NSDictionary *user = [NSMutableDictionary dictionary];        
        [user setValue:[rs stringForColumnIndex:0] forKey:@"id"];
        [user setValue:[rs stringForColumnIndex:1] forKey:@"nick"];
        [user setValue:[rs stringForColumnIndex:2] forKey:@"password"];
        [user setValue:[[rs stringForColumnIndex:3] objectFromJSONString] forKey:@"nodesCompleted"];
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
    
    void (^onCompletion)() = ^(AFHTTPRequestOperation *op, id res)
    {
        BOOL reqSuccess = res != nil && ![res isKindOfClass:[NSError class]];
        NSLog(@"success = %@", reqSuccess ? @"YES" : @"NO");
        if (reqSuccess)
        {
            NSArray *updates = [(NSData*)res objectFromJSONData];
            NSLog(@"%@", updates);
            [usersDatabase open];
            for (NSDictionary *updatedUr in updates)
            {
                NSString *urId = [updatedUr objectForKey:@"id"];
                
                FMResultSet *rs = [usersDatabase executeQuery:@"SELECT id, nick, nodesCompleted FROM users WHERE id = ?", urId];
                // chance user has been deleted since sync request sent
                if ([rs next])
                {
                    // possibility that updated user has changed on client since request to server was made
                    NSMutableSet *nodesCompletedSet = [NSSet setWithArray:[updatedUr objectForKey:@"nodesCompleted"]];
                    [nodesCompletedSet addObjectsFromArray:[[rs stringForColumn:@"nodes_completed"] objectFromJSONString]];
                    
                    NSArray *nodesCompleted = [nodesCompletedSet allObjects];
                    
                    BOOL updateSuccess = [usersDatabase executeUpdate:@"UPDATE users SET nodes_completed = ? WHERE id = ?", [nodesCompleted JSONString], urId];                    
                    NSLog(@"update success='%@': user id='%@', nick='%@',  nodesCompleted=%@"
                          , updateSuccess?@"TRUE":@"FALSE", [updatedUr objectForKey:@"id"], [updatedUr objectForKey:@"nick"], [updatedUr objectForKey:@"nodesCompleted"]);
                    
                    if (currentUser && [[currentUser objectForKey:@"id"] isEqualToString:urId])
                    {
                        NSMutableDictionary *ur = [currentUser mutableCopy];
                        [ur setValue:nodesCompleted forKey:@"nodesCompleted"];
                        [currentUser release];
                        currentUser = [ur copy];
                        [ur release];
                    }
                }
            }
            [usersDatabase close];
            isSyncing = NO;
        }
    };
    AFHTTPRequestOperation *reqOp = [[[AFHTTPRequestOperation alloc] initWithRequest:req] autorelease];
    [reqOp setCompletionBlockWithSuccess:onCompletion failure:onCompletion];
    [opQueue addOperation:reqOp];
    isSyncing = YES;
}

-(NSDictionary*)userFromCurrentRowOfResultSet:(FMResultSet*)rs
{
    NSMutableDictionary *user = [NSMutableDictionary dictionary];
    [user setValue:[rs stringForColumn:@"id"] forKey:@"id"];
    [user setValue:[rs stringForColumn:@"nick"] forKey:@"nickName"];
    [user setValue:[rs stringForColumn:@"nodes_completed"] forKey:@"nodesCompleted"];
    return [[user copy] autorelease];
}

-(void)dealloc
{
    if (usersDatabase) [usersDatabase release];
    if (httpClient) [httpClient release];
    if (opQueue) [opQueue release];
    [super dealloc];
}

@end
