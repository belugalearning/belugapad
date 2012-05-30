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

@property (readwrite, retain) NSString *currentProblemAttemptID;
@end

@implementation UsersService

@synthesize installationUUID;
@synthesize currentUser;
@synthesize currentProblemAttemptID;

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
        currentUserSession = nil;
    }
    
    if (ur)
    {    
        currentUserSession = [[UserSession alloc] initAndStartSessionForUser:ur onDevice:device];        
        if (!ur.nodesCompleted)
        {
            ur.nodesCompleted = [NSArray array];
            [[ur save] wait];   
        }
    }
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

-(NSArray*)deviceUsersByNickName
{
    // The view named kDeviceUsersLastSessionStart will pull back the most recent session start for each user on each device
    // key: [deviceId, userId]      value:sessionStart
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kDeviceUsersLastSessionStart];
    q.groupLevel = 2;
    q.startKey = [NSArray arrayWithObjects:device.document.documentID, nil];
    q.endKey = [NSArray arrayWithObjects:device.document.documentID, [NSDictionary dictionary], nil];
    [[q start] wait];
    
    NSMutableArray *users = [NSMutableArray array];
    for (CouchQueryRow *row in q.rows)
    {
        CouchDocument *userDoc = [database documentWithID:row.key1];
        User *user = [[CouchModelFactory sharedInstance] modelForDocument:userDoc];
        if (user) [users addObject:user];
    }
    
    return [users sortedArrayUsingComparator:^(id a, id b) {
        return [[(NSString*)((User*)a).nickName lowercaseString] compare:[(NSString*)((User*)b).nickName lowercaseString]];
    }];
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

-(User*) getNewUserWithNickName:(NSString*)nickName
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

    //expose the id of the current event -- used in touch logging reconciliation
    currentProblemAttemptID=currentProblemAttempt.document.documentID;
    
    [self logProblemAttemptEvent:kProblemAttemptStart withOptionalNote:nil];
    [[currentProblemAttempt save] wait];
}

-(void)logProblemAttemptEvent:(ProblemAttemptEvent)event
             withOptionalNote:(NSString*)note
{
    if (!currentProblemAttempt) return;
    
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
        case kProblemAttemptAppResignActive:
            eventString = @"APP_RESIGN_ACTIVE";
            break;
        case kProblemAttemptAppBecomeActive:
            eventString = @"APP_BECOME_ACTIVE";
            break;
        case kProblemAttemptAppEnterBackground:
            eventString = @"APP_ENTER_BACKGROUND";
            break;
        case kProblemAttemptAppEnterForeground:
            eventString = @"APP_ENTER_FOREGROUND";
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
        case kProblemAttemptUserCommit:
            eventString = @"PROBLEM_ATTEMPT_USER_COMMIT";
            break;
            
        case kProblemAttemptToolHostPinch:
            eventString = @"PROBLEM_ATTEMPT_TOOLHOST_PINCH";
            break;
            
        case kProblemAttemptNumberPickerNumberFromPicker:
            eventString = @"PROBLEM_ATTEMPT_NUMBERPICKER_NUMBER_FROM_PICKER";
            break;
            
        case kProblemAttemptNumberPickerNumberFromRegister:
            eventString = @"PROBLEM_ATTEMPT_NUMBERPICKER_NUMBER_FROM_REGISTER";
            break;
            
        case kProblemAttemptNumberPickerNumberMove:
            eventString = @"PROBLEM_ATTEMPT_NUMBERPICKER_NUMBER_MOVE";
            break;
            
        case kProblemAttemptNumberPickerNumberDelete:
            eventString = @"PROBLEM_ATTEMPT_NUMBERPICKER_NUMBER_DELETE";
            break;
            
        case kProblemAttemptMetaQuestionChangeAnswer:
            eventString = @"PROBLEM_ATTEMPT_METAQUESTION_CHANGE_ANSWER";
            break;
            
        case kProblemAttemptPartitionToolTouchBeganOnCagedObject:
            eventString = @"PROBLEM_ATTEMPT_PARTITIONTOOL_TOUCH_BEGAN_ON_CAGED_OBJECT";
            break;
            
        case kProblemAttemptPartitionToolTouchMovedMoveBlock:
            eventString = @"PROBLEM_ATTEMPT_PARTITIONTOOL_TOUCH_MOVED_MOVE_BLOCK";
            break;
            
        case kProblemAttemptPartitionToolTouchBeganOnRow:
            eventString = @"PROBLEM_ATTEMPT_PARTITIONTOOL_TOUCH_BEGAN_ON_ROW";
            break;
            
        case kProblemAttemptPartitionToolTouchEndedOnRow:
            eventString = @"PROBLEM_ATTEMPT_PARTITIONTOOL_TOUCH_ENDED_ON_ROW";
            break;
            
        case kProblemAttemptPartitionToolTouchEndedInSpace:
            eventString = @"PROBLEM_ATTEMPT_PARTITIONTOOL_TOUCH_ENDED_IN_SPACE";
            break;
            
        case kProblemAttemptPartitionToolTouchBeganOnLockedRow:
            eventString = @"PROBLEM_ATTEMPT_PARTITIONTOOL_TOUCH_BEGAN_ON_LOCKED_ROW";
            break;
            
        case kProblemAttemptDotGridTouchBeginCreateShape:
            eventString = @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_BEGAN_CREATE_SHAPE";
            break;
        
        case kProblemAttemptDotGridTouchEndedCreateShape:
            eventString = @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_ENDED_CREATE_SHAPE";
            break;
            
        case kProblemAttemptDotGridTouchBeginResizeShape:
            eventString = @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_BEGAN_RESIZE_SHAPE";
            break;
            
        case kProblemAttemptDotGridTouchEndedResizeShape:
            eventString = @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_ENDED_CREATE_SHAPE";
            break;
            
        case kProblemAttemptDotGridTouchBeginSelectTile:
            eventString = @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_BEGAN_SELECT_TILE";
            break;
            
        case kProblemAttemptDotGridTouchBeginDeselectTile:
            eventString = @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_BEGAN_DESELECT_TILE";
            break;
            
        case kProblemAttemptDotGridTouchEndedInvalidResizeHidden:
            eventString = @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_ENDED_INVALID_RESIZE_HIDDEN";
            break;
            
        case kProblemAttemptDotGridTouchEndedInvalidResizeExistingTile:
            eventString = @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_ENDED_INVALID_RESIZE_EXISTING_TILE";
            break;
            
        case kProblemAttemptDotGridTouchEndedInvalidCreateHidden:
            eventString = @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_ENDED_INVALID_CREATE_HIDDEN";
            break;
            
        case kProblemAttemptDotGridTouchEndedInvalidCreateExistingTile:
            eventString = @"PROBLEM_ATTEMPT_DOTGRID_TOUCH_ENDED_INVALID_CREATE_EXISTING_TILE";
            break;
            
        case kProblemAttemptLongDivisionTouchEndedChangedActiveRow:
            eventString = @"PROBLEM_ATTEMPT_LONGDIVISION_TOUCH_ENDED_CHANGED_ACTIVE_ROW";
            break;
            
        case kProblemAttemptLongDivisionTouchMovedMoveRow:
            eventString = @"PROBLEM_ATTEMPT_LONGDIVISION_TOUCH_MOVED_MOVE_ROW";
            break;
            
        case kProblemAttemptLongDivisionTouchEndedIncrementActiveNumber:
            eventString = @"PROBLEM_ATTEMPT_LONGDIVISION_TOUCH_ENDED_INCREMENT_ACTIVE_NUMBER";
            break;
            
        case kProblemAttemptLongDivisionTouchEndedDecrementActiveNumber:
            eventString = @"PROBLEM_ATTEMPT_LONGDIVISION_TOUCH_ENDED_DECREMENT_ACTIVE_NUMBER";
            break;
            
        case kProblemAttemptLongDivisionTouchEndedPanningTopSection:
            eventString = @"PROBLEM_ATTEMPT_LONGDIVISION_TOUCH_ENDED_PANNING_TOPSECTION";
            break;
            
        case kProblemAttemptTimesTablesTouchBeginHighlightRow:
            eventString = @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_HIGHLIGHT_ROW";
            break;
            
        case kProblemAttemptTimesTablesTouchBeginHighlightColumn:
            eventString = @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_HIGHLIGHT_COLUMN";
            break;
            
        case kProblemAttemptTimesTablesTouchBeginUnhighlightRow:
            eventString = @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_UNHIGHLIGHT_ROW";
            break;
            
        case kProblemAttemptTimesTablesTouchBeginUnhighlightColumn:
            eventString = @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_UNHIGHLIGHT_COLUMN";
            break;
            
        case kProblemAttemptTimesTablesTouchBeginRevealAnswer:
            eventString = @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_REVEAL_ANSWER";
            break;
            
        case kProblemAttemptTimesTablesTouchBeginSelectAnswer:
            eventString = @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_SELECT_ANSWER";
            break;
            
        case kProblemAttemptTimesTablesTouchBeginDeselectAnswer:
            eventString = @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_DESELECT_ANSWER";
            break;
            
        case kProblemAttemptTimesTablesTouchBeginTapDisabledBox:
            eventString = @"PROBLEM_ATTEMPT_TIMESTABLES_TOUCH_BEGIN_TAP_DISABLED_BOX";
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
