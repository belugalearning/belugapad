//
//  ProblemAttempt.m
//  belugapad
//
//  Created by Nicholas Cartwright on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ProblemAttempt.h"
#import "Problem.h"

#import <CouchCocoa/CouchCocoa.h>

@interface ProblemAttempt()
{
@private
    NSTimeInterval timePaused;
    NSMutableDictionary *currentPause;
}
@end

@implementation ProblemAttempt

@dynamic user, problemId, problemRevisionId, dateTimeStart, dateTimeEnd, pauses, timeInPlay, success, interactionEvents;

- (id) initWithNewDocumentInDatabase:(CouchDatabase*)database
                             AndUser:(User*)user
                          AndProblem:(Problem*)problem
{
    NSParameterAssert(database);
    self = [super initWithDocument: nil];
    if (self)
    {
        self.database = database;
        self.user = user;
        self.problemId = problem.document.documentID;
        self.problemRevisionId = [problem.document propertyForKey:@"_rev"];
        self.dateTimeStart = [NSDate date];
        self.dateTimeEnd = nil;
        self.pauses = [NSMutableArray array];
        self.timeInPlay = 0;
        self.success = false;
        self.interactionEvents = [NSMutableArray array];
        
        self.autosaves  = YES;
        
        timePaused = 0;
    }
    return self;
}

-(void) togglePause
{
    if (!currentPause)
    {
        // start pause
        NSDate *start = [NSDate date];
        
        currentPause = [[NSMutableDictionary dictionaryWithObject:[RESTBody JSONObjectWithDate:start] forKey:@"start"] retain];
        [(NSMutableArray*)self.pauses addObject:currentPause];
    }
    else
    {
        // end pause
        NSDate *end = [NSDate date];
        NSDate *start = [RESTBody dateWithJSONObject:[currentPause objectForKey:@"start"]];
        
        timePaused += [end timeIntervalSinceDate:start];
        
        [currentPause setObject:[RESTBody JSONObjectWithDate:end] forKey:@"end"];
        [currentPause release];        
    }
}

-(void) endAttempt:(BOOL)success
{
    self.success = (success ? true : false);
    if (currentPause) [self togglePause];
    self.dateTimeEnd = [NSDate date];    
    self.timeInPlay = [self.dateTimeEnd timeIntervalSinceDate:self.dateTimeStart] - timePaused;
    [self save]; // perhaps overkill is autosaving
}

-(void)dealloc
{
    if (currentPause) [currentPause release];
    [super dealloc];
}

@end
