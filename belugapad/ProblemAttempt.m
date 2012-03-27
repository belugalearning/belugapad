//
//  ProblemAttempt.m
//  belugapad
//
//  Created by Nicholas Cartwright on 20/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ProblemAttempt.h"
#import "Problem.h"
#import "User.h"

#import <CouchCocoa/CouchCocoa.h>

@interface ProblemAttempt()
{
@private
    NSTimeInterval timePaused;
    NSMutableDictionary *currentPause;
    NSArray *problemAssessmentCriteria;
}
@end

@implementation ProblemAttempt

@dynamic type;
@dynamic userId;
@dynamic userNickName;
@dynamic problemId;
@dynamic problemRevisionId;
@dynamic elementId;
@dynamic elementRevisionId;
@dynamic elementName;
@dynamic moduleId;
@dynamic moduleRevisionId;
@dynamic moduleName;
@dynamic topicId;
@dynamic topicRevisionId;
@dynamic topicName;
@dynamic dateTimeStart;
@dynamic dateTimeEnd;
@dynamic onStartUserEvents;
@dynamic onEndUserEvents;
@dynamic pauses;
@dynamic timeInPlay;                                                                                                                                                                   
@dynamic success;                                                                                                                                                                                 
@dynamic interactionEvents;
@dynamic pointsAwarded;                                                                                                                                                               
@dynamic elementCompletionOnEnd;

- (id) initAndStartAttemptForUser:(User*)user
                       andProblem:(Problem*)problem
                onStartUserEvents:(NSArray*)events;
{   
    self = [super initWithDocument: nil];
    if (self)
    {
        self.database = user.database;
        self.type = @"problem attempt";
        
        self.userId = user.document.documentID;
        self.userNickName = user.nickName;
        
        self.problemId = problem.document.documentID;
        self.problemRevisionId = [problem.document propertyForKey:@"_rev"];
        
        CouchDatabase *contentDb = problem.database;
        
        CouchDocument *t = [contentDb documentWithID:problem.topicId];
        self.topicId = t.documentID;
        self.topicRevisionId = [t propertyForKey:@"_rev"];
        self.topicName = [t propertyForKey:@"name"];
        
        CouchDocument *m = [contentDb documentWithID:problem.moduleId];
        self.moduleId = m.documentID;
        self.moduleRevisionId = [m propertyForKey:@"_rev"];
        self.moduleName = [m propertyForKey:@"name"];
        
        CouchDocument *e = [contentDb documentWithID:problem.elementId];
        self.elementId = e.documentID;
        self.elementRevisionId = [e propertyForKey:@"_rev"];
        self.elementName = [e propertyForKey:@"name"];
        
        self.dateTimeStart = [NSDate date];
        self.dateTimeEnd = nil;
        
        self.onStartUserEvents = events;
        
        self.pauses = [NSMutableArray array];
        self.timeInPlay = 0;
        self.success = false;
        self.interactionEvents = [NSMutableArray array];
        
        [[self save] wait];
        
        timePaused = 0;
        problemAssessmentCriteria = [problem.assessmentCriteria copy];
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
        NSMutableArray *mutableCopyPauses = [[self.pauses mutableCopy] autorelease];
        [mutableCopyPauses addObject:currentPause];
        self.pauses = mutableCopyPauses;
    }
    else
    {
        // end pause
        NSDate *end = [NSDate date];
        NSDate *start = [RESTBody dateWithJSONObject:[currentPause objectForKey:@"start"]];
        
        timePaused += [end timeIntervalSinceDate:start];
        
        [currentPause setObject:[RESTBody JSONObjectWithDate:end] forKey:@"end"];
        [currentPause release];
        currentPause = nil;
    }
    
    [[self save] wait];
}

-(void) endAttempt:(BOOL)success
{
    if (currentPause) [self togglePause];
    self.dateTimeEnd = [NSDate date];
    self.timeInPlay = [self.dateTimeEnd timeIntervalSinceDate:self.dateTimeStart] - timePaused;
    
    self.success = (success ? true : false);
    if (success)
    {
        // TODO: currently akways awarding max assessment criteria points!!!!
        NSMutableArray *points = [NSMutableArray array];
        for (NSDictionary *d in problemAssessmentCriteria)
        {
            NSString *criterionId = [d objectForKey:@"id"];
            NSString *maxScore = [d objectForKey:@"maxScore"];
            [points addObject:[NSDictionary dictionaryWithObjectsAndKeys:maxScore, @"points", criterionId, @"criterionId", nil]];
        }
        self.pointsAwarded = points;
    }
    
    [[self save] wait];
}

-(void)dealloc
{
    if (currentPause) [currentPause release];
    if (problemAssessmentCriteria) [problemAssessmentCriteria release];
    [super dealloc];
}

@end
