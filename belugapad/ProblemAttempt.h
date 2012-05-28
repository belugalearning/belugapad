//
//  ProblemAttempt.h
//  belugapad
//
//  Created by Nicholas Cartwright on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CouchCocoa/CouchCocoa.h>
#import "UsersService.h"
@class UserSession, Problem;

@interface ProblemAttempt : CouchModel

@property (retain) NSString *type;
@property (retain) UserSession *userSession;
@property (retain) Problem *problem;
@property (retain) NSString *problemRev;
@property (retain) Problem *parentProblem;
@property (retain) NSString *parentProblemRev;
@property (retain) NSArray *events;

- (id) initAndStartAttemptForUserSession:(UserSession*)userSession
                              andProblem:(Problem*)problem
                        andParentProblem:(Problem*)parentProblem
                        andGeneratedPDEF:(NSDictionary*)pdef;

@end