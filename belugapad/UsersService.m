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
#import "UserSession.h"
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
NSString * const kDeviceUsersLastSessionStart = @"most-recent-session-start-per-device-user";
NSString * const kUsersByNickName = @"users-by-nick-name";
NSString * const kUsersByNickNamePassword = @"users-by-nick-name-password";
NSString * const kUsersTimeInPlay = @"users-time-in-play";
NSString * const kProblemsCompletedByUser = @"problems-completed-by-user";

@interface UsersService()
{
    @private
    NSString *installationUUID;
    Device *device;
    UserSession *currentUserSession;
    
    CouchDatabase *database;
    CouchReplication *pushReplication;
    CouchReplication *pullReplication;
    
    ProblemAttempt *currentProblemAttempt;
}
-(NSString*)generateUUID;
@end

@implementation UsersService

@synthesize installationUUID;
@synthesize currentUser;

-(User*)currentUser
{
    if (!currentUserSession) return nil;
    return currentUserSession.user;
}

-(void)setCurrentUser:(User*)ur
{
    if (currentUserSession)
    {
        currentUserSession.dateEnd = [NSDate date];
        [[currentUserSession save] wait];
        [currentUserSession release];
    }
    
    currentUserSession = [[UserSession alloc] initAndStartSessionForUser:ur onDevice:device];
    
    if (!ur.nodesCompleted) ur.nodesCompleted = [NSArray array];
    [[ur save] wait];
}

-(id)init
{
    self = [super init];
    if (self)
    {
        [[CouchModelFactory sharedInstance] registerClass:[Device class] forDocumentType:@"device"];
        [[CouchModelFactory sharedInstance] registerClass:[User class] forDocumentType:@"user"];
        [[CouchModelFactory sharedInstance] registerClass:[UserSession class] forDocumentType:@"user session"];
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

        pushReplication = [[database pushToDatabaseAtURL:[NSURL URLWithString:kRemoteUsersDatabaseURI]] retain];
        pushReplication.continuous = YES;
        pullReplication = [[database pullFromDatabaseAtURL:[NSURL URLWithString:kRemoteUsersDatabaseURI]] retain];
        pullReplication.continuous = YES;
    }
    return self;
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

-(void)startProblemAttempt
{   
    if (currentProblemAttempt)
    {
        [currentProblemAttempt release];
        currentProblemAttempt = nil;
    }
    
    AppController *ad = (AppController*)[[UIApplication sharedApplication] delegate];
    ContentService *cs = ad.contentService;
    Problem *currentProblem = cs.currentProblem;
        
    currentProblemAttempt = [[ProblemAttempt alloc] initAndStartAttemptForUserSession:currentUserSession
                                                                           andProblem:currentProblem
                                                                     andParentProblem:nil
                                                                     andGeneratedPDEF:cs.currentStaticPdef];
    
    [self logProblemAttemptEvent:kProblemAttemptStart withOptionalNote:nil];
    [[currentProblemAttempt save] wait];
}

-(void)logProblemAttemptEvent:(ProblemAttemptEvent)event
             withOptionalNote:(NSString*)note
{
    if (currentProblemAttempt)
    {
        NSString *eventString = nil;
        switch (event) {
            case kProblemAttemptStart:
                eventString = @"PROBLEM_ATTEMPT_START";
                break;
            case kProblemAttemptUserPause:
                eventString = @"PROBLEM_ATTEMPT_USER_PAUSE";
                break;
            case kProblemAttemptUserResume:
                eventString = @"PROBLEM_ATTEMPT_USER_RESUME";
                break;
            case kProblemAttemptAppResign:
                eventString = @"APP_RESIGN";
                break;
            case kProblemAttemptAppResume:
                eventString = @"APP_RESUME";
                break;
            case kProblemAttemptAbandonApp:
                eventString = @"ABANDON_APP";
                break;
            case kProblemAttemptSuccess:
                eventString = @"PROBLEM_ATTEMPT_SUCCESS";
                break;
            case kProblemAttemptExitToMap:
                eventString = @"PROBLEM_ATTEMPT_EXIT_TO_MAP";
                break;
            case kProblemAttemptExitLogOut:
                eventString = @"PROBLEM_ATTEMPT_EXIT_LOG_OUT";
                break;
            case kProblemAttemptUserReset:
                eventString = @"PROBLEM_ATTEMPT_USER_RESET";
                break;
            case kProblemAttemptSkip:
                eventString = @"PROBLEM_ATTEMPT_SKIP";
                break;
            case kProblemAttemptSkipWithSuggestion:
                eventString = @"PROBLEM_ATTEMPT_SKIP_WITH_SUGGESTION";
                break;
            case kProblemAttemptSkipDebug:
                eventString = @"PROBLEM_ATTEMPT_SKIP_DEBUG";
                break;
            case kProblemAttemptFail:
                eventString = @"PROBLEM_ATTEMPT_FAIL";
                break;
            case kProblemAttemptFailWithChildProblem:
                eventString = @"PROBLEM_ATTEMPT_FAIL_WITH_CHILD_PROBLEM";
                break;            
            default:
                // TODO: ERROR - LOG TO DATABASE!
                break;
        }
        if (eventString)
        { 
            NSMutableArray *events = [[currentProblemAttempt.events mutableCopy] autorelease];
            NSDictionary *e = [NSDictionary dictionaryWithObjectsAndKeys:
                                    eventString, @"eventType",
                                    [RESTBody JSONObjectWithDate:[NSDate date]], @"date",
                                    note, @"note", nil];
            [events addObject:e];
            currentProblemAttempt.events = events;
            [[currentProblemAttempt save] wait];
        }
    }
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

-(NSString*)generateUUID
{
    CFUUIDRef UUIDRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef UUIDSRef = CFUUIDCreateString(kCFAllocatorDefault, UUIDRef);
    NSString *uuid = [NSString stringWithFormat:@"%@", UUIDSRef];
    
    CFRelease(UUIDRef);
    CFRelease(UUIDSRef);
    
    return uuid;
}

-(void)dealloc
{
    if (currentUserSession) [currentUserSession release];
    [device release];
    [pushReplication release];
    [pullReplication release];
    [super dealloc];
}
    

@end
