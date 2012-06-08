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
    BOOL problemAttemptLoggingIsEnabled;
    NSString *contentSource;
    
    NSString *installationUUID;
    Device *device;
    User *user;
    UserSession *currentUserSession;
    
    CouchDatabase *usersDatabase;
    CouchDatabase *loggingDatabase;
    
    CouchReplication *usersPushReplication;
    CouchReplication *usersPullReplication;
    CouchReplication *loggingPushReplication;
    
    ProblemAttempt *currentProblemAttempt;
}
-(NSString*)generateUUID;

@property (readwrite, retain) NSString *currentProblemAttemptID;
@end

@implementation UsersService

@synthesize installationUUID;
@synthesize currentUser;
@synthesize currentProblemAttemptID;

-(void)setCurrentUser:(User*)ur
{
    if (currentUserSession)
    {
        currentUserSession.dateEnd = [NSDate date];
        [[currentUserSession save] wait];
        [currentUserSession release];
        currentUserSession = nil;
    }
    
    //user = ur;
    [ur retain];
    [currentUser release];
    currentUser=ur;
    
    if (ur)
    {    
        currentUserSession = [[UserSession alloc] initWithNewDocumentInDatabase:loggingDatabase
                                                         AndStartSessionForUser:ur
                                                                       onDevice:device
                                                              withContentSource:contentSource];
    }
}

-(id)initWithProblemPipeline:(NSString*)source;
{
    self = [super init];
    if (self)
    {
        problemAttemptLoggingIsEnabled = [@"DATABASE" isEqualToString:source];
        contentSource = source;
        
        [[CouchModelFactory sharedInstance] registerClass:[Device class] forDocumentType:@"device"];
        [[CouchModelFactory sharedInstance] registerClass:[User class] forDocumentType:@"user"];
        [[CouchModelFactory sharedInstance] registerClass:[UserSession class] forDocumentType:@"user session"];
        [[CouchModelFactory sharedInstance] registerClass:[ProblemAttempt class] forDocumentType:@"problem attempt"];
        
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
        loggingPushReplication = [[loggingDatabase pushToDatabaseAtURL:[NSURL URLWithString:kRemoteLoggingDatabaseURI]] retain];
        loggingPushReplication.continuous = YES;
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

-(void)startProblemAttempt
{
    if (!problemAttemptLoggingIsEnabled) return;
    
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
    if (!problemAttemptLoggingIsEnabled) return;
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
        
        case kProblemAttemptNumberLineTouchBeginPickupBubble:
            eventString = @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_BEGIN_PICKUP_BUBBLE";
            break;
        
        case kProblemAttemptNumberLineTouchEndedReleaseBubble:
            eventString = @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_ENDED_RELEASE_BUBBLE";
            break;
        
        case kProblemAttemptNumberLineTouchMovedMoveBubble:
            eventString = @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_MOVED_MOVE_BUBBLE";
            break;
        
        case kProblemAttemptNumberLineTouchEndedIncreaseSelection:
            eventString = @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_ENDED_INCREASE_SELECTION";
            break;
        
        case kProblemAttemptNumberLineTouchEndedDecreaseSelection:
            eventString = @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_ENDED_DECREASE_SELECTION";
            break;
            
        case kProblemAttemptNumberLineTouchMovedMoveLine:
            eventString = @"PROBLEM_ATTEMPT_NUMBERLINE_TOUCH_MOVED_MOVE_LINE";
            break;
            
        case kProblemAttemptPlaceValueTouchBeginPickupCageObject:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_BEGIN_PICKUP_CAGE_OBJECT";
            break;
            
        case kProblemAttemptPlaceValueTouchBeginPickupGridObject:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_BEGIN_PICKUP_GRID_OBJECT";
            break;
            
        case kProblemAttemptPlaceValueTouchEndedDropObjectOnCage:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_ENDED_DROP_OBJECT_ON_CAGE";
            break;
            
        case kProblemAttemptPlaceValueTouchEndedDropObjectOnGrid:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_ENDED_DROP_OBJECT_ON_GRID";
            break;
            
        case kProblemAttemptPlaceValueTouchEndedCondenseObject:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_ENDED_CONDENSE_OBJECT";
            break;
            
        case kProblemAttemptPlaceValueTouchEndedMulchObjects:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_ENDED_MULCH_OBJECTS";
            break;
            
        case kProblemAttemptPlaceValueTouchMovedMoveObject:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_MOVED_MOVE_OBJECT";
            break;
            
        case kProblemAttemptPlaceValueTouchMovedMoveObjects:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_MOVED_MOVE_OBJECTS";
            break;
            
        case kProblemAttemptPlaceValueTouchBeginSelectObject:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_BEGIN_SELECT_OBJECT";
            break;
            
        case kProblemAttemptPlaceValueTouchBeginDeselectObject:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_BEGIN_DESELECT_OBJECT";
            break;
            
        case kProblemAttemptPlaceValueTouchBeginCountObject:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_BEGIN_COUNT_OBJECT";
            break;
            
        case kProblemAttemptPlaceValueTouchBeginUncountObject:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_BEGIN_UNCOUNT_OBJECT";
            break;
            
        case kProblemAttemptPlaceValueTouchMovedMoveGrid:
            eventString = @"PROBLEM_ATTEMPT_PLACEVALUE_TOUCH_MOVED_MOVE_GRID";
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
        
        NSLog(@"logged %@", eventString);
    }
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
    [usersPushReplication release];
    [usersPullReplication release];
    [loggingPushReplication release];
    [super dealloc];
}

@end
