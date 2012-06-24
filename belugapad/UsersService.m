//
//  UsersService.m
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "UsersService.h"
#import "Device.h"
#import "User.h"
#import "LoggingService.h"
#import "UserSession.h"
#import "Problem.h"
#import "AppDelegate.h"
#import "ContentService.h"
#import "JSONKit.h"
#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchDesignDocument_Embedded.h>
#import <CouchCocoa/CouchModelFactory.h>

NSString * const kRemoteUsersDatabaseURI = @"http://u.zubi.me:5984/may2012-users";
NSString * const kRemoteLoggingDatabaseURI = @"http://u.zubi.me:5984/may2012-logging";
NSString * const kLocalUserDatabaseName = @"may2012-users";
NSString * const kLocalLoggingDatabaseName = @"may2012-logging";
NSString * const kDefaultDesignDocName = @"users-views";
NSString * const kDeviceUsersLastSessionStart = @"most-recent-session-start-per-device-user";
NSString * const kUsersByNickName = @"users-by-nick-name";
NSString * const kUsersByNickNamePassword = @"users-by-nick-name-password";
NSString * const kUsersTimeInPlay = @"users-time-in-play";
NSString * const kProblemsCompletedByUser = @"problems-completed-by-user";

@interface UsersService()
{
    @private
    LoggingService *loggingService;
    NSString *contentSource;
    
    NSString *installationUUID;
    Device *device;
    User *user;
    
    CouchDatabase *usersDatabase;
    CouchDatabase *loggingDatabase;
    
    CouchReplication *usersPushReplication;
    CouchReplication *usersPullReplication;
    CouchReplication *loggingPushReplication;
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
    
    [loggingService onUpdateObjectOfContext:BL_USER_SESSION_CONTEXT];
}

-(id)initWithProblemPipeline:(NSString*)source
           andLoggingService:(LoggingService *)ls
{
    self = [super init];
    if (self)
    {
        contentSource = source;
        loggingService = [ls retain];
        
        [[CouchModelFactory sharedInstance] registerClass:[Device class] forDocumentType:@"device"];
        [[CouchModelFactory sharedInstance] registerClass:[User class] forDocumentType:@"user"];
        [[CouchModelFactory sharedInstance] registerClass:[UserSession class] forDocumentType:@"user session"];
        
        CouchEmbeddedServer *server = [CouchEmbeddedServer sharedInstance];
        
        usersDatabase = [server databaseNamed:kLocalUserDatabaseName];
        RESTOperation* op = [usersDatabase create];
        if (![op wait] && op.error.code != 412)
        {
            self = nil;
            return self;
        }
        usersDatabase.tracksChanges = YES;
        
        loggingDatabase = [server databaseNamed:kLocalLoggingDatabaseName];
        op = [loggingDatabase create];
        if (![op wait] && op.error.code != 412)
        {
            self = nil;
            return self;
        }
        
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        if (![standardUserDefaults objectForKey:@"installationUUID"])
        {
            // This is the first run of the app on the device
            
            // create device doc
            CouchDocument *deviceDoc = [loggingDatabase untitledDocument];
            RESTOperation *op = [deviceDoc putProperties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          @"device", @"type"
                                                          , [RESTBody JSONObjectWithDate:[NSDate date]], @"firstLaunchDateTime", nil]];
            if (![op wait])
            {
                self = nil;
                return self;
            }
            
            [standardUserDefaults setObject:deviceDoc.documentID forKey:@"installationUUID"];
        }
        
        installationUUID = [standardUserDefaults objectForKey:@"installationUUID"];
        device = [[[CouchModelFactory sharedInstance] modelForDocument:[loggingDatabase documentWithID:installationUUID]] retain];
        device.autosaves = true;

        usersPushReplication = [[usersDatabase pushToDatabaseAtURL:[NSURL URLWithString:kRemoteUsersDatabaseURI]] retain];
        usersPushReplication.continuous = YES;
        usersPullReplication = [[usersDatabase pullFromDatabaseAtURL:[NSURL URLWithString:kRemoteUsersDatabaseURI]] retain];
        usersPullReplication.continuous = YES;
    }
    
    return self;
}

-(NSArray*)deviceUsersByLastSessionDate
{
    // The view named kDeviceUsersLastSessionStart will pull back the most recent session start for each user on each device
    // key: [deviceId, userId]      value:sessionStart
    CouchQuery *q = [[loggingDatabase designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kDeviceUsersLastSessionStart];
    q.groupLevel = 2;
    q.startKey = [NSArray arrayWithObjects:device.document.documentID, nil];
    q.endKey = [NSArray arrayWithObjects:device.document.documentID, [NSDictionary dictionary], nil];
    [[q start] wait];
    
    // now need to sort the users themselves by their most recent session start
    NSArray *sortedBySessionStartDesc = [[q rows].allObjects sortedArrayUsingComparator:^(id a, id b) {
        return [(NSString*)((CouchQueryRow*)b).value compare:(NSString*)((CouchQueryRow*)a).value];
    }];
    
    NSMutableArray *users = [NSMutableArray array];
    for (CouchQueryRow *row in sortedBySessionStartDesc)
    {
        CouchDocument *userDoc = [usersDatabase documentWithID:row.key1];
        User *ur = [[CouchModelFactory sharedInstance] modelForDocument:userDoc];
        if (ur) [users addObject:ur];
    }
    
    return [[users copy] autorelease];
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
    if (loggingService) [loggingService release];
    [device release];
    [usersPushReplication release];
    [usersPullReplication release];
    [loggingPushReplication release];
    [super dealloc];
}

@end
