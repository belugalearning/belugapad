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
#import "User.h"
#import "JSONKit.h"
#import "FMDatabase.h"

@interface UsersService()
{
    @private
    LoggingService *loggingService;
    NSString *contentSource;
    
    FMDatabase *usersDatabase;
    
    User *user;
}
@end

@implementation UsersService

@synthesize installationUUID;
@synthesize currentUser;

-(void)setCurrentUser:(User*)ur
{ 
    //user = ur;
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
        
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![[NSFileManager defaultManager] fileExistsAtPath:usersDatabasePath])
        {
            
        }
        else
        {
            usersDatabase = [FMDatabase databaseWithPath:usersDatabasePath];
        }
        [usersDatabase retain];
    }
    
    return self;
}

-(NSArray*)deviceUsersByNickName
{
    [loggingService sendData];
    
    // The view named kDeviceUsersLastSessionStart will pull back the most recent session start for each user on each device
    // key: [deviceId, userId]      value:sessionStart
    CouchQuery *q = [[loggingDatabase designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kDeviceUsersLastSessionStart];
    q.groupLevel = 2;
    q.startKey = [NSArray arrayWithObjects:device.document.documentID, nil];
    q.endKey = [NSArray arrayWithObjects:device.document.documentID, [NSDictionary dictionary], nil];
    [[q start] wait];
    
    NSMutableArray *users = [NSMutableArray array];
    for (CouchQueryRow *row in q.rows)
    {
        CouchDocument *userDoc = [usersDatabase documentWithID:row.key1];
        User *ur = [[CouchModelFactory sharedInstance] modelForDocument:userDoc];
        if (ur) [users addObject:ur];
    }
    
    return [users sortedArrayUsingComparator:^(id a, id b) {
        return [[(NSString*)((User*)a).nickName lowercaseString] compare:[(NSString*)((User*)b).nickName lowercaseString]];
    }];
}

-(BOOL) nickNameIsAvailable:(NSString*)nickName
{
    CouchQuery *q = [[usersDatabase designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kUsersByNickName];
    q.keys = [NSArray arrayWithObject:nickName];
    q.prefetch = YES;
    [[q start] wait];
    return [[q rows] count] == 0;
}

-(User*) userMatchingNickName:(NSString*)nickName
                  andPassword:(NSString*)password
{
    CouchQuery *q = [[usersDatabase designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kUsersByNickNamePassword];
    q.keys = [NSArray arrayWithObject:[NSArray arrayWithObjects:nickName, password, nil]];
    [[q start] wait];
    
    if ([[q rows] count] == 0) return nil;
    
    return [[CouchModelFactory sharedInstance] modelForDocument:((CouchQueryRow*)[[q rows].allObjects objectAtIndex:0]).document];
}

-(User*) getNewUserWithNickName:(NSString*)nickName
                    andPassword:(NSString*)password
                   andZubiColor:(NSData*)color // rgba
              andZubiScreenshot:(UIImage*)image
{
    User *u = [[[User alloc] initWithNewDocumentInDatabase:usersDatabase] autorelease];
    u.nickName = nickName;
    u.password = password;
    u.zubiColor = color;
    u.zubiScreenshot = image;
    u.autosaves = YES;
    RESTOperation *op = [u save];
    [op wait];
    return u;
}

-(void)addCompletedNodeId:(NSString *)nodeId
{
    NSMutableArray *nc = [currentUser.nodesCompleted mutableCopy];
    [nc addObject:nodeId];    
    currentUser.nodesCompleted = nc;
    [[currentUser save] wait];
    [nc release];
}

-(BOOL)hasCompletedNodeId:(NSString *)nodeId
{
    if (!currentUser.nodesCompleted) return NO;
    return [currentUser.nodesCompleted containsObject:nodeId];
}

-(void)dealloc
{
    if (usersDatabase) [usersDatabase release];
    [super dealloc];
}

@end
