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
@property (retain) NSString *userId;
@property (retain) NSString *userNickName;
@property (retain) NSString *problemId;
@property (retain) NSString *problemRevisionId;
@property (retain) NSString *elementId;
@property (retain) NSString *elementRevisionId;
@property (retain) NSString *elementName;
@property (retain) NSString *moduleId;
@property (retain) NSString *moduleRevisionId;
@property (retain) NSString *moduleName;
@property (retain) NSString *topicId;
@property (retain) NSString *topicRevisionId;
@property (retain) NSString *topicName;
@property (retain) NSDate *dateTimeStart;
@property (retain) NSDate *dateTimeEnd;
@property (retain) NSArray *onStartUserEvents;
@property (retain) NSArray *onEndUserEvents;
@property (retain) NSArray *pauses;
@property  NSTimeInterval timeInPlay;
@property bool success;
@property (retain) NSArray *interactionEvents;
@property (retain) NSArray *pointsAwarded;
@property double elementCompletionOnEnd;

- (id) initAndStartAttemptForUser:(User*)user
                       andProblem:(Problem*)problem
                onStartUserEvents:(NSArray*)events;

-(void) endAttempt:(BOOL)success;

-(void) togglePause;

@end