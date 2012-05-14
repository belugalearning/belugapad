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
#import "Problem.h"
#import "ProblemAttempt.h"
#import "AppDelegate.h"
#import "ContentService.h"
#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchDesignDocument_Embedded.h>
#import <CouchCocoa/CouchModelFactory.h>

NSString * const kRemoteUsersDatabaseURI = @"http://u.zubi.me:5984/blm-users";
NSString * const kLocalUserDatabaseName = @"users";
NSString * const kDefaultDesignDocName = @"users-views";
NSString * const kDeviceUsersLastSessionStart = @"device-users-last-session";
NSString * const kUsersByNickName = @"users-by-nick-name";
NSString * const kUsersByNickNamePassword = @"users-by-nick-name-password";
NSString * const kUsersTimeInPlay = @"users-time-in-play";
NSString * const kProblemsCompletedByUser = @"problems-completed-by-user";
NSString * const kTotalExpByUser = @"total-exp-by-user";

@interface UsersService()
{
    @private
    NSString *installationUUID;
    Device *device;
    NSMutableDictionary *currentUserSession;
    
    CouchDatabase *database;
    CouchReplication *pushReplication;
    CouchReplication *pullReplication;
    
    ProblemAttempt *currentProblemAttempt;
}
-(NSDate*)currentUserSessionStart;
@end

@implementation UsersService

@synthesize installationUUID;
@synthesize currentUser;

// use a dict instead?
+(NSString*)userEventString:(UserEvents)event
{
    switch(event)
    {
        case kUserEventCompleteProblem:
            return @"user-complete-problem";
        case kUserEventCompleteNode:
            return @"user-complete-node";
    }
}

-(id)init
{
    self = [super init];
    if (self)
    {
        [[CouchModelFactory sharedInstance] registerClass:[Device class] forDocumentType:@"device"];
        [[CouchModelFactory sharedInstance] registerClass:[User class] forDocumentType:@"user"];        
        [[CouchModelFactory sharedInstance] registerClass:[ProblemAttempt class] forDocumentType:@"problem attempt"];
        
        CouchEmbeddedServer *server = [CouchEmbeddedServer sharedInstance];
        
        database = [server databaseNamed:kLocalUserDatabaseName];
        RESTOperation* op = [database create];
        if (![op wait] && op.error.code != 412)
        {
            self = nil;
            return self;
        }
        database.tracksChanges = YES;
        
        NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
        if (![standardUserDefaults objectForKey:@"installationUUID"])
        {
            // This is the first run of the app on the device
            CouchDocument *deviceDoc = [database untitledDocument];
            RESTOperation *op = [deviceDoc putProperties:[NSDictionary dictionaryWithObjectsAndKeys:
                                                          @"device", @"type"
                                                          , [RESTBody JSONObjectWithDate:[NSDate date]], @"firstLaunchDateTime"
                                                          , [NSArray array], @"userSessions", nil]];
            if (![op wait])
            {
                self = nil;
                return self;
            }
            
            [standardUserDefaults setObject:deviceDoc.documentID forKey:@"installationUUID"];
        }
        
        installationUUID = [standardUserDefaults objectForKey:@"installationUUID"];
        device = [[[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:installationUUID]] retain];
        device.autosaves = true;

//        pushReplication = [[database pushToDatabaseAtURL:[NSURL URLWithString:kRemoteUsersDatabaseURI]] retain];
//        pushReplication.continuous = YES;
//        pullReplication = [[database pullFromDatabaseAtURL:[NSURL URLWithString:kRemoteUsersDatabaseURI]] retain];
//        pullReplication.continuous = YES;
    }
    return self;
}

-(void)addCompletedNodeId:(NSString *)nodeId
{
    NSMutableArray *nc;
    
    if (!currentUser.nodesCompleted)
    {
        nc = [NSMutableArray array];
    }
    else
    {
        nc = [currentUser.nodesCompleted mutableCopy];
    }
    
    [nc addObject:nodeId];
    
    currentUser.nodesCompleted = nc;
    [[currentUser save] wait];
}

-(BOOL)hasCompletedNodeId:(NSString *)nodeId
{
    if (!currentUser.nodesCompleted) return NO;
    return [currentUser.nodesCompleted containsObject:nodeId];
}

-(User*)currentUser
{
    // TODO: This is a quick fix. I've done something wrong. Shouldn't need to store the user on the app delegate
    AppController *ad = (AppController*)[[UIApplication sharedApplication] delegate];
    return  ad.currentUser;
}

-(void)setCurrentUser:(User*)ur
{
    NSString *now = [RESTBody JSONObjectWithDate:[NSDate date]];
    
    if (currentUser)
    {
        [currentUserSession setObject:now forKey:@"endDateTime"];
        [currentUser release];
    }
    
    if (!ur.nodesCompleted) ur.nodesCompleted = [NSArray array];
    [[ur save] wait];
    
    currentUser = [ur retain];
    // TODO: This is a quick fix. I've done something wrong. Shouldn't need to store the user on the app delegate
    AppController *ad = (AppController*)[[UIApplication sharedApplication] delegate];
    ad.currentUser = ur;
    
    currentUserSession = [NSMutableDictionary dictionary];
    [currentUserSession setObject:ur.document.documentID forKey:@"userId"];
    [currentUserSession setObject:now forKey:@"startDateTime"];
    
    NSMutableArray *userSessions = [[device.userSessions mutableCopy] autorelease];
    [userSessions addObject:currentUserSession];
    device.userSessions = userSessions;
    [[device save] wait];
}

-(NSArray*)deviceUsersByLastSessionDate
{
    // The view named kDeviceUsersLastSessionStart will pull back the most recent session start for each user on each device
    // key: [deviceId, userId]      value:sessionStart
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kDeviceUsersLastSessionStart];
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
        CouchDocument *userDoc = [database documentWithID:row.key1];
        User *user = [[CouchModelFactory sharedInstance] modelForDocument:userDoc];
        if (user) [users addObject:user];
    }
    
    return [[users copy] autorelease];
}

-(BOOL) nickNameIsAvailable:(NSString*)nickName
{
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kUsersByNickName];
    q.keys = [NSArray arrayWithObject:nickName];
    q.prefetch = YES;
    [[q start] wait];
    return [[q rows] count] == 0;
}

-(User*) userMatchingNickName:(NSString*)nickName
                  andPassword:(NSString*)password
{
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kUsersByNickNamePassword];
    q.keys = [NSArray arrayWithObject:[NSArray arrayWithObjects:nickName, password, nil]];
    [[q start] wait];
    
    if ([[q rows] count] == 0) return nil;
    
    return [[CouchModelFactory sharedInstance] modelForDocument:((CouchQueryRow*)[[q rows].allObjects objectAtIndex:0]).document];
}

-(User*) createUserWithNickName:(NSString*)nickName
                    andPassword:(NSString*)password
                    andZubiColor:(NSData*)color // rgba
               andZubiScreenshot:(UIImage*)image
{
    User *u = [[[User alloc] initWithNewDocumentInDatabase:database] autorelease];
    u.nickName = nickName;
    u.password = password;
    u.zubiColor = color;
    u.zubiScreenshot = image;
    u.autosaves = YES;
    RESTOperation *op = [u save];
    [op wait];
    return u;
}

-(double)currentUserTotalTimeInApp
{
    NSString *urId = self.currentUser.document.documentID;
    
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kUsersTimeInPlay];
    q.groupLevel = 1;
    q.startKey = [NSArray arrayWithObject:urId];
    q.endKey = [NSArray arrayWithObjects:urId, [NSDictionary dictionary], nil];
    [[q start] wait];
    
    // should have 1 row returned
    if (![[q rows] count]) return 0;
    
    CouchQueryRow *r = [[q rows].allObjects objectAtIndex:0];
    return [(NSNumber*)r.value doubleValue];
}

-(NSUInteger)currentUserTotalExp
{
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kTotalExpByUser];
    q.groupLevel = 1;
    q.keys = [NSArray arrayWithObject:self.currentUser.document.documentID];
    [[q start] wait];
    
    if (![[q rows] count]) return 0;
    
    CouchQueryRow *r = [[q rows].allObjects objectAtIndex:0];
    return [(NSNumber*)r.value unsignedIntValue];
}

-(void)startProblemAttempt
{   
    if (currentProblemAttempt)
    {
        // TODO: Shouldn't be here. Handle properly
        [currentProblemAttempt endAttempt:NO];
        [currentProblemAttempt release];
    }
    
    AppController *ad = (AppController*)[[UIApplication sharedApplication] delegate];
    ContentService *cs = ad.contentService;
    Problem *currentProblem = cs.currentProblem;
    
    User *ur = self.currentUser;
    
    // events populated with strings form UsersService#userEvents
    NSMutableArray *events = [NSMutableArray array];
    
    // previously arrays on user doc like topicsStarted, topicsCompleted etc. were updated here
    //[[ur save] wait];
        
    currentProblemAttempt = [[ProblemAttempt alloc] initAndStartAttemptForUser:ur
                                                                    andProblem:currentProblem
                                                             onStartUserEvents:events];
}

-(void) togglePauseProblemAttempt
{
    if (!currentProblemAttempt) return; // TODO: Handle Error properly
    [currentProblemAttempt togglePause];
}

-(void) endProblemAttempt:(BOOL)success
{
    if (!currentProblemAttempt) return; // TODO: Handle Error properly
    [currentProblemAttempt endAttempt:success];
    
    User *ur = self.currentUser;

    if (success)
    {
        // N.B. previously logging events on currentProblemAttempt relating to completing topics/modules/elements
        //    AppController *ad = (AppController*)[[UIApplication sharedApplication] delegate];
        //    ContentService *cs = ad.contentService;
        //    CouchDatabase *contentDb = [cs Database];
        //    Problem *p = [[CouchModelFactory sharedInstance] modelForDocument:[contentDb documentWithID:currentProblemAttempt.problemId]];
        
        // events populated with strings from UsersService#userEventString
        NSMutableArray *events = [NSMutableArray arrayWithObject:[UsersService userEventString:kUserEventCompleteProblem]];
        
        currentProblemAttempt.onEndUserEvents = events;
    }
    [[ur save] wait];
    [[currentProblemAttempt save] wait];
    [currentProblemAttempt release];
    currentProblemAttempt = nil;
}

-(NSDate*)currentUserSessionStart
{
    if (!self.currentUser) return nil; // TODO: handle properly - error
    
    NSString *urId = self.currentUser.document.documentID;
    
    NSDictionary *currentSession = [device.userSessions lastObject];
    if (!currentSession || ![urId isEqualToString:[currentSession objectForKey:@"userId"]])
    {
        // TODO: error - handle properly
        return nil;
    }
    
    return [RESTBody dateWithJSONObject:[currentSession objectForKey:@"startDateTime"]];
}

-(void)dealloc
{
    [device release];
    [pushReplication release];
    [pullReplication release];
    [super dealloc];
}
    

@end
