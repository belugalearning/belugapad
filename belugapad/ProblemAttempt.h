//
//  ProblemAttempt.h
//  belugapad
//
//  Created by Nicholas Cartwright on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>
@class User, Problem;

@interface ProblemAttempt : CouchModel

@property (retain) NSString *type;
@property (retain) User *user;
@property (retain) NSString *userNickName;
@property (retain) Problem *problem;
@property (retain) NSString *problemRev;
@property (retain) NSDate *dateTimeStart;
@property (retain) NSDate *dateTimeEnd;
@property (retain) NSArray *onStartUserEvents;
@property (retain) NSArray *onEndUserEvents;
@property (retain) NSArray *pauses;
@property  NSTimeInterval timeInPlay;
@property bool success;
@property (retain) NSArray *interactionEvents;
@property (retain) NSArray *pointsAwarded;

- (id) initAndStartAttemptForUser:(User*)user
                       andProblem:(Problem*)problem
                onStartUserEvents:(NSArray*)events;

-(void) endAttempt:(BOOL)success;

-(void) togglePause;

@end