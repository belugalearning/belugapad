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
#import "Module.h"
#import "Element.h"
#import "ActivityFeedEvent.h"
#import "AppDelegate.h"
#import "ContentService.h"
#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchDesignDocument_Embedded.h>
#import <CouchCocoa/CouchModelFactory.h>
#import <CouchCocoa/CouchTouchDBServer.h>

NSString * const kRemoteUsersDatabaseURI = @"http://www.soFarAslant.com:5984/temp-blm-users";
NSString * const kLocalUserDatabaseName = @"users";
NSString * const kDefaultDesignDocName = @"default";
NSString * const kDeviceUsersLastSessionStart = @"device-users-last-session";
NSString * const kAllUserNicknames = @"all-user-nick-names";
NSString * const kUsersByNickNamePassword = @"users-by-nick-name-password";
NSString * const kUsersTimeInPlay = @"users-time-in-play";
//NSString * const kProblemSuccessByUserElementDate = @"problem-success-by-user-element-date";
NSString * const kProblemsCompletedByUser = @"problems-completed-by-user";
NSString * const kTotalExpByUser = @"total-exp-by-user";
NSString * const kActivityFeedEventsByUserDate = @"activity-feed-events-by-user-date";

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
-(void)createViews;
-(void)startLiveQueries;
-(NSDate*)currentUserSessionStart;
@end

@implementation UsersService

@synthesize installationUUID;
@synthesize currentUser;

-(id)init
{
    self = [super init];
    if (self)
    {
        [[CouchModelFactory sharedInstance] registerClass:[Device class] forDocumentType:@"device"];
        [[CouchModelFactory sharedInstance] registerClass:[User class] forDocumentType:@"user"];        
        [[CouchModelFactory sharedInstance] registerClass:[ProblemAttempt class] forDocumentType:@"problem attempt"];
        [[CouchModelFactory sharedInstance] registerClass:[ActivityFeedEvent class] forDocumentType:@"activity feed event"];
        
        CouchTouchDBServer *server = [CouchTouchDBServer sharedInstance];
        
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
        
        [self createViews];
        [self startLiveQueries];

        pushReplication = [[database pushToDatabaseAtURL:[NSURL URLWithString:kRemoteUsersDatabaseURI]] retain];
        pushReplication.continuous = YES;
        pullReplication = [[database pullFromDatabaseAtURL:[NSURL URLWithString:kRemoteUsersDatabaseURI]] retain];
        pullReplication.continuous = YES;
    }
    return self;
}

-(User*)currentUser
{
    // TODO: This is a quick fix. I've done something wrong. Shouldn't need to store the user on the app delegate
    AppDelegate *ad = [[UIApplication sharedApplication] delegate];
    return  ad.currentUser;
}

-(void)setCurrentUser:(User*)user
{
    NSString *now = [RESTBody JSONObjectWithDate:[NSDate date]];
    
    if (currentUser)
    {
        [currentUserSession setObject:now forKey:@"endDateTime"];
        [currentUser release];
    }
    
    currentUser = [user retain];
    currentUser.currentModuleId = nil;
    currentUser.currentElementId = nil;
    
    currentUserSession = [NSMutableDictionary dictionary];
    [currentUserSession setObject:user.document.documentID forKey:@"userId"];
    [currentUserSession setObject:now forKey:@"startDateTime"];
    
    NSMutableArray *userSessions = [device.userSessions mutableCopy];
    [userSessions addObject:currentUserSession];
    device.userSessions = userSessions;
    [[device save] wait];
    
    // TODO: This is a quick fix. I've done something wrong. Shouldn't need to store the user on the app delegate
    AppDelegate *ad = [[UIApplication sharedApplication] delegate];
    ad.currentUser = user;
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
    
    return [users copy];
}

-(BOOL) nickNameIsAvailable:(NSString*)nickName
{
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kAllUserNicknames];
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

-(double)currentUserTotalPlayingElement:(NSString *)elementId
{
    NSString *urId = self.currentUser.document.documentID;
    
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kUsersTimeInPlay];
    q.groupLevel = 1;
    q.startKey = [NSArray arrayWithObjects:urId, elementId, nil];
    q.endKey = [NSArray arrayWithObjects:urId, elementId, [NSDictionary dictionary], nil];
    [[q start] wait];
    
    // should have 1 row returned
    if (![[q rows] count]) return 0;
    
    CouchQueryRow *r = [[q rows].allObjects objectAtIndex:0];
    return [(NSNumber*)r.value doubleValue];
}

-(double)currentUserPercentageCompletionOfElement:(Element*)element
{
    NSString *urId = self.currentUser.document.documentID;
    
    NSMutableArray *keys = [NSMutableArray array];
    for (NSString *pId in element.includedProblems)
    {
        [keys addObject:[NSArray arrayWithObjects:urId, pId, nil]];
    }
    
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kProblemsCompletedByUser];
    q.groupLevel = 2;
    q.keys = keys;
    [[q start] wait];
    
    return [[q rows] count] / (double)[element.includedProblems count];
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

/*-(NSString*) lastCompletedProblemIdInElementWithId:(NSString*)elementId
                                         andUserId:(NSString*)userId
{
    CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kProblemSuccessByUserElementDate];
    q.descending = YES;
    q.startKey = [NSArray arrayWithObjects:elementId, userId, [NSDictionary dictionary], nil];
    q.endKey = [NSArray arrayWithObjects:elementId, userId, nil];
    [[q start] wait];
    
    if (![[q rows] count]) return nil;
    
    CouchQueryRow *latest = [[q rows].allObjects objectAtIndex:0];
    return latest.value;
}*/

-(void)startProblemAttempt
{
    if (currentProblemAttempt)
    {
        // TODO: This is horrible quick pre-emptive fix. If currentProblemAttempt != nil, there's an issue. Hopefully will never end up here!
        [currentProblemAttempt endAttempt:NO];
        [currentProblemAttempt release];
    }
    
    AppDelegate *ad = [[UIApplication sharedApplication] delegate];
    ContentService *cs = ad.contentService;
    CouchDatabase *contentDb = [cs Database];
    Problem *currentProblem = cs.currentProblem;
    
    User *ur = self.currentUser;    
    NSString *mId = currentProblem.moduleId;
    NSString *eId = currentProblem.elementId;
    
    if (!ur.modulesStarted) ur.modulesStarted = [NSArray array];
    if (!ur.elementsStarted) ur.elementsStarted = [NSArray array];
    
    ActivityFeedEvent *e = nil;
    
    if (![ur.modulesStarted containsObject:mId])
    {
        NSMutableArray *mStarted = [ur.modulesStarted mutableCopy];
        [mStarted addObject:mId];
        ur.modulesStarted = mStarted;
        e = [[ActivityFeedEvent alloc] initWithNewDocumentInDatabase:database usersService:self contentDatabase:contentDb eventType:kStartModule entityId:mId points:0];
        [[e save] wait];
        [e release];
        e = nil;
    }
    
    if (![ur.currentModuleId isEqualToString:mId])
    {
        ur.currentModuleId = mId;
        e = [[ActivityFeedEvent alloc] initWithNewDocumentInDatabase:database usersService:self contentDatabase:contentDb eventType:kPlayingModule entityId:mId points:0];
        [[e save] wait];
        [e release];
        e = nil;
    }
    
    if (![ur.elementsStarted containsObject:eId])
    {
        NSMutableArray *eStarted = [ur.elementsStarted mutableCopy];
        [eStarted addObject:eId];
        ur.elementsStarted = eStarted;
        
        e = [[ActivityFeedEvent alloc] initWithNewDocumentInDatabase:database usersService:self contentDatabase:contentDb eventType:kStartElement entityId:eId points:0];
        [[e save] wait];
        [e release];
        e = nil;
    }
    
    if (![ur.currentElementId isEqualToString:eId])
    {
        ur.currentElementId = eId;
        e = [[ActivityFeedEvent alloc] initWithNewDocumentInDatabase:database usersService:self contentDatabase:contentDb eventType:kPlayingElement entityId:eId points:0];
        [[e save] wait];
        [e release];
        e = nil;
    }
    
    [ur save];
        
    currentProblemAttempt = [[ProblemAttempt alloc] initWithNewDocumentInDatabase:database
                                                                        andUserId:ur.document.documentID
                                                                       andProblem:currentProblem];
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
    
    if (success)
    {
        // award assessment criteria points.
        // for now we're awarding max points
        AppDelegate *ad = [[UIApplication sharedApplication] delegate];
        ContentService *cs = ad.contentService;
        CouchDatabase *contentDb = [cs Database];
        Problem *p = cs.currentProblem;
        NSUInteger totalPoints = 0;
        
        NSMutableArray *awarded = [NSMutableArray array];
        for (NSDictionary *criterion in p.assessmentCriteria)
        {
            NSNumber *points = [criterion objectForKey:@"maxScore"];
            totalPoints += [points unsignedIntValue];
            
            NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:[criterion objectForKey:@"id"], @"id", points, @"points", nil];
            [awarded addObject:d];
        }
        currentProblemAttempt.awardedAssessmentCriteriaPoints = awarded;

        [[currentProblemAttempt save] wait];
        
        User *ur = self.currentUser;
        ActivityFeedEvent *e = nil;
        e = [[ActivityFeedEvent alloc] initWithNewDocumentInDatabase:database usersService:self contentDatabase:contentDb eventType:kCompleteProblem entityId:p.document.documentID points:totalPoints];
        [[e save] wait];
        [e release];
        e = nil;
        
        if (!self.currentUser.elementsCompleted) ur.elementsCompleted = [NSArray array];
        if (!self.currentUser.modulesCompleted) ur.modulesCompleted = [NSArray array];
        
        if (![ur.elementsCompleted containsObject:p.elementId])
        {
            Element *el = [[CouchModelFactory sharedInstance] modelForDocument:[contentDb documentWithID:p.elementId]];
            double elCompletion = [self currentUserPercentageCompletionOfElement:el];
            if (elCompletion >= 1)
            {
                NSMutableArray *completedElements = [self.currentUser.elementsCompleted mutableCopy];
                [completedElements addObject:p.elementId];
                ur.elementsCompleted = completedElements;
                e = [[ActivityFeedEvent alloc] initWithNewDocumentInDatabase:database usersService:self contentDatabase:contentDb eventType:kCompleteElement entityId:p.elementId points:0];
                [[e save] wait];
                [e release];
                e = nil;
            }
        }
        
        if (![ur.modulesCompleted containsObject:p.moduleId])
        {
            Module *mod = [[CouchModelFactory sharedInstance] modelForDocument:[contentDb documentWithID:p.moduleId]];
            NSSet *modElements = [NSSet setWithArray:mod.elements];
            NSSet *completedElements = [NSSet setWithArray:ur.elementsCompleted];
            BOOL modCompleted = [modElements isSubsetOfSet:completedElements];
            
            if (modCompleted)
            {
                NSMutableArray *completedModules = [ur.modulesCompleted mutableCopy];
                [completedModules addObject:p.moduleId];
                self.currentUser.modulesCompleted = completedModules;
                e = [[ActivityFeedEvent alloc] initWithNewDocumentInDatabase:database usersService:self contentDatabase:contentDb eventType:kCompleteModule entityId:p.moduleId points:0];
                [[e save] wait];
                [e release];
                e = nil;
            }
        }
                
    }
    [[self.currentUser save] wait];
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

-(void)createViews
{
    CouchDesignDocument* design = [database designDocumentWithName:kDefaultDesignDocName];
    
    [design defineViewNamed:kDeviceUsersLastSessionStart
                   mapBlock:^(NSDictionary* doc, void (^emit)(id key, id value)) {
                       id type = [doc objectForKey:@"type"];
                       if (type && 
                           [type respondsToSelector:@selector(isEqualToString:)] && 
                           [type isEqualToString:@"device"])
                       {
                           for (NSDictionary *session in [doc objectForKey:@"userSessions"])
                           {
                               emit([NSArray arrayWithObjects:[doc objectForKey:@"_id"], [session objectForKey:@"userId"], nil], [session objectForKey:@"startDateTime"]);
                           }
                       }
                   }
                reduceBlock:^id(NSArray* keys, NSArray* values, BOOL rereduce) {
                    NSSortDescriptor *sd = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO selector:@selector(localizedCaseInsensitiveCompare:)];
                    NSArray *sessionsByStartDesc = [values sortedArrayUsingDescriptors:[NSArray arrayWithObject:sd]];
                    return [sessionsByStartDesc objectAtIndex:0];
                }
                    version: @"v1.05"];
    
    
    [design defineViewNamed:kAllUserNicknames
                   mapBlock:^(NSDictionary* doc, void (^emit)(id key, id value)) {
                       id type = [doc objectForKey:@"type"];
                       if (type &&
                           [type respondsToSelector:@selector(isEqualToString:)] &&
                           [type isEqualToString:@"user"])
                       {
                           emit([doc objectForKey:@"nickName"], nil);
                       }
                   }
                    version: @"v1.05"];
    
    
    [design defineViewNamed:kUsersByNickNamePassword
                        mapBlock:MAPBLOCK({        
        id type = [doc objectForKey:@"type"];        
        
        if (type && 
            [type respondsToSelector:@selector(isEqualToString:)] && 
            [type isEqualToString:@"user"])
        {
            emit([NSArray arrayWithObjects:[doc objectForKey:@"nickName"], [doc objectForKey:@"password"], nil], nil);
        }
    })
                    version: @"v1.00"];
    
    
    [design defineViewNamed:kProblemsCompletedByUser // query view with groupLevel = 2.
                   mapBlock:^(NSDictionary* doc, void (^emit)(id key, id value)) {
                       id type = [doc objectForKey:@"type"];
                       id success = [doc objectForKey:@"success"];
                       
                       if (type && 
                           [type respondsToSelector:@selector(isEqualToString:)] && 
                           [type isEqualToString:@"problem attempt"] &&
                           (bool)success == true)
                       {
                           NSArray *key = [NSArray arrayWithObjects:[doc objectForKey:@"userId"], [doc objectForKey:@"problemId"], nil];
                           emit(key, [doc objectForKey:@"problemId"]);
                       }
                   }
                reduceBlock:^id(NSArray* keys, NSArray* values, BOOL rereduce) {
                    return [values objectAtIndex:0];
                }
                    version: @"v1.05"];    
    
    [design defineViewNamed:kTotalExpByUser  // query view with groupLevel = 1
                   mapBlock:^(NSDictionary* doc, void (^emit)(id key, id value)) {
                       id type = [doc objectForKey:@"type"];
                       id success = [doc objectForKey:@"success"];
                       if (type && 
                           [type respondsToSelector:@selector(isEqualToString:)] && 
                           [type isEqualToString:@"problem attempt"] &&
                                                                      (bool)success == true)
                       {
                           NSArray *acPoints = [doc objectForKey:@"awardedAssessmentCriteriaPoints"];
                           for (NSDictionary *crit in acPoints)
                           {
                               emit([doc objectForKey:@"userId"], [crit objectForKey:@"points"]);
                           }
                       }
                   }
                reduceBlock:^id(NSArray* keys, NSArray* values, BOOL rereduce) {
                    NSUInteger sum = 0;
                    for (NSNumber *points in values)
                    {
                        sum += [points unsignedIntValue];
                    }
                    return [NSNumber numberWithUnsignedInt:sum];
                }
                    version: @"v1.00"];
    
    [design defineViewNamed:kUsersTimeInPlay // query view with groupLevel=1 (all time in play for user), or groupLevel=2 (time in play on per element per user)
                    mapBlock:^(NSDictionary* doc, void (^emit)(id key, id value)) {
                        id type = [doc objectForKey:@"type"];                        
                        if (type && 
                            [type respondsToSelector:@selector(isEqualToString:)] && 
                            [type isEqualToString:@"problem attempt"])
                        {
                            NSArray *key = [NSArray arrayWithObjects:[doc objectForKey:@"userId"], [doc objectForKey:@"elementId"], nil];
                            emit(key, [doc objectForKey:@"timeInPlay"]);
                        }
                    }
                reduceBlock:^id(NSArray* keys, NSArray* values, BOOL rereduce) {
                    double sum = 0;
                    for (NSNumber *num in values)
                    {
                        sum += [num doubleValue];
                    }
                    return [NSNumber numberWithDouble:sum];
                }
                    version: @"v1.02"];
    
/*    [design defineViewNamed:kProblemSuccessByUserElementDate
                   mapBlock:^(NSDictionary* doc, void (^emit)(id key, id value)){
                       id type = [doc objectForKey:@"type"];
                       if (type && 
                           [type respondsToSelector:@selector(isEqualToString:)] && 
                           [type isEqualToString:@"problem attempt"] &&
                           (bool)[doc objectForKey:@"success"] == true)
                       {
                           NSArray *key = [NSArray arrayWithObjects:[doc objectForKey:@"user"], [doc objectForKey:@"elementId"], [doc objectForKey:@"dateTimeEnd"], nil];
                           emit(key, [doc objectForKey:@"problemId"]);
                       }
                   }
                    version: @"v1.01"];
                
  */  
}

-(void)startLiveQueries
{
}

-(void)dealloc
{
    [device release];
    [pushReplication release];
    [pullReplication release];
    [super dealloc];
}
    

@end
