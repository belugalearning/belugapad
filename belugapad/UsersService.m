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

@interface UsersService()
{
@private
    FMDatabase *usersDatabase;
    LoggingService *loggingService;
    NSString *contentSource;
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
        
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *usersDatabasePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"users.db"];
        
        usersDatabase = [[FMDatabase databaseWithPath:usersDatabasePath] retain];
        [usersDatabase open];        
        if (![usersDatabase tableExists:@"users"]) [usersDatabase executeUpdate:@"CREATE TABLE users (id TEXT, nick TEXT, password TEXT, nodes_completed TEXT)"];
        [usersDatabase close];
        
    }
    
    return self;
}

-(NSArray*)deviceUsersByNickName
{
    [loggingService sendData];
    
    NSMutableArray *users = [[NSMutableArray array] retain];
    
    [usersDatabase open];
    FMResultSet *rs = [usersDatabase executeQuery:@"SELECT id, nick, nodes_completed FROM users ORDER BY nick"];
    while([rs next])
        [users addObject:[self userFromCurrentRowOfResultSet:rs]];
    [rs close];
    [usersDatabase close];
    return users;
}

-(BOOL) nickNameIsAvailable:(NSString*)nickName
{
    // TODO: This only checks local database of users - needs to check with server
    [usersDatabase open];
    FMResultSet *rs = [usersDatabase executeQuery:@"SELECT 1 FROM users WHERE nick = ?", nickName];
    BOOL isAvailable = ![rs next];
    [rs close];
    [usersDatabase close];
    return isAvailable;
}

-(NSDictionary*) userMatchingNickName:(NSString*)nickName
                  andPassword:(NSString*)password
{
    [usersDatabase open];
    FMResultSet *rs = [usersDatabase executeQuery:@"SELECT 1 FROM users WHERE nick=? AND password=?", nickName, password];

    if (![rs next]) return nil;
    
    NSDictionary *u = [self userFromCurrentRowOfResultSet:rs];
    
    [rs close];
    [usersDatabase close];
    
    return u;
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
    NSMutableArray *nc = [[currentUser objectForKey:@"nodesCompleted"] mutableCopy];
    [nc addObject:nodeId];
    
    [usersDatabase open];
    
    [usersDatabase executeUpdate:@"UPDATE users SET nodes_completed = ? WHERE id = ?)", [nc JSONString], urId];
    
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

-(NSDictionary*)userFromCurrentRowOfResultSet:(FMResultSet*)rs
{
    NSString *nodesCompletedText = [rs stringForColumn:@"nodes_completed"];
    NSArray *nodesCompleted = [nodesCompletedText length] > 0 ? [nodesCompletedText objectFromJSONString] : [NSArray array];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:
            [rs stringForColumn:@"id"], @"id"
            , [rs stringForColumn:@"nick"], @"nickName"
            , nodesCompleted, @"nodesCompleted"
            , nil];
}

-(void)dealloc
{
    if (usersDatabase) [usersDatabase release];
    [super dealloc];
}

@end
