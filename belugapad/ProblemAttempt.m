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
@dynamic events;

- (id) initAndStartAttemptForUserSession:(UserSession*)userSession
                              andProblem:(Problem*)problem
                        andParentProblem:(Problem*)parentProblem
                        andGeneratedPDEF:(NSDictionary*)pdef
{
    self = [super initWithDocument: nil];
    if (self)
    {
        self.database = userSession.database;
        self.type = @"problem attempt";        
        self.userSession = userSession;
        self.problem = problem._id;
        self.problemRev = problem._rev;
        if (parentProblem)
        {            
            self.parentProblem = parentProblem._id;
            self.parentProblemRev = parentProblem._rev;
        }
        self.events = [NSMutableArray array];        
        if (pdef)
        {
            NSString *libDir = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
            NSString *filePath = [NSString stringWithFormat:@"%@/pdef.plist", libDir];
            [pdef writeToFile:filePath atomically:NO];
            [self createAttachmentWithName:@"pdef.plist" type:@"application/xml" body:[NSData dataWithContentsOfFile:filePath]];
        }
    }
    return self;
}

-(void)dealloc
{
    [super dealloc];
}

@end
