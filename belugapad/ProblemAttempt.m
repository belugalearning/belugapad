//
//  ProblemAttempt.m
//  belugapad
//
//  Created by Nicholas Cartwright on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ProblemAttempt.h"
#import "Problem.h"
#import "UserSession.h"
#import "UsersService.h"

#import <CouchCocoa/CouchCocoa.h>

@interface ProblemAttempt()
{
@private
}
@end

@implementation ProblemAttempt

@dynamic type;
@dynamic userSession;
@dynamic problem;
@dynamic problemRev;
@dynamic parentProblem;
@dynamic parentProblemRev;
@dynamic generatedPDEF;
@dynamic events;

- (id) initAndStartAttemptForUserSession:(UserSession*)userSession
                              andProblem:(Problem*)problem
                        andParentProblem:(Problem*)parentProblem
                        andGeneratedPDEF:(NSString*)pdef
{
    self = [super initWithDocument: nil];
    if (self)
    {
        self.database = userSession.database;
        self.type = @"problem attempt";        
        self.userSession = userSession;
        self.problem = problem;
        self.problemRev = [problem.document propertyForKey:@"_rev"];
        if (parentProblem)
        {            
            self.parentProblem = parentProblem;
            self.parentProblemRev = [parentProblem.document propertyForKey:@"_rev"];
        }
        self.generatedPDEF = pdef; 
        self.events = [NSMutableArray array];
    }
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

@end
