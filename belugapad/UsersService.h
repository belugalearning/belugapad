//
//  UsersService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 12/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class User, ProblemAttempt, CouchLiveQuery, CouchEmbeddedServer;

// see ProblemAttempt#logEvent
typedef enum {
    kProblemAttemptError,
    kProblemAttemptStart,
    kProblemAttemptUserPause,
    kProblemAttemptUserResume,
    kProblemAttemptAppResign,
    kProblemAttemptAppResume,
    kProblemAttemptAbandonApp,
    kProblemAttemptSuccess,
    kProblemAttemptExitToMap,
    kProblemAttemptExitLogOut,
    kProblemAttemptUserReset,
    kProblemAttemptSkip,
    kProblemAttemptSkipWithSuggestion,
    kProblemAttemptSkipDebug,
    kProblemAttemptFail,
    kProblemAttemptFailWithChildProblem
} ProblemAttemptEvent;

@interface UsersService : NSObject

@property (readonly, retain, nonatomic) NSString *installationUUID;
@property (retain, nonatomic) User *currentUser;

-(NSArray*)deviceUsersByLastSessionDate;

-(BOOL) nickNameIsAvailable:(NSString*)nickName;

-(User*) createUserWithNickName:(NSString*)nickName
                    andPassword:(NSString*)password
                   andZubiColor:(NSData*)color // rgba
              andZubiScreenshot:(UIImage*)image;

-(User*) userMatchingNickName:(NSString*)nickName
                  andPassword:(NSString*)password;

-(void)startProblemAttempt;
-(void)logProblemAttemptEvent:(ProblemAttemptEvent)event
             withOptionalNote:(NSString*)note;

-(void)addCompletedNodeId:(NSString*)nodeId;
-(BOOL)hasCompletedNodeId:(NSString*)nodeId;

@end