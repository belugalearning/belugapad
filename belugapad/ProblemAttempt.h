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

@property (retain) User *user;
@property (retain) NSString *problemId;
@property (retain) NSString *problemRevisionId;
@property (retain) NSString *elementId;
@property (retain) NSDate *dateTimeStart;
@property (retain) NSDate *dateTimeEnd;
@property (retain) NSArray *pauses;
@property  NSTimeInterval timeInPlay;
@property bool success;
@property (retain) NSArray *interactionEvents;

- (id) initWithNewDocumentInDatabase:(CouchDatabase*)database
                             AndUser:(User*)user
                          AndProblem:(Problem*)problem;

-(void) togglePause;

@end
