//
//  ContentService.m
//  belugapad
//
//  Created by Nicholas Cartwright on 17/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ContentService.h"
#import "global.h"
#import "AppDelegate.h"
#import "BAExpressionHeaders.h"
#import "BATio.h"
#import "Problem.h"
#import "Element.h"
#import "Module.h"
#import "Topic.h"
#import "Syllabus.h"
#import "ProblemAttempt.h"
#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchDesignDocument_Embedded.h>
#import <CouchCocoa/CouchModelFactory.h>
#import <CouchCocoa/CouchTouchDBServer.h>

@interface ContentService()
{
@private
    BOOL useTestPipeline;    
    
    NSArray *testProblemList;
    NSUInteger currentPIndex;
}
@property (nonatomic, readwrite, retain) NSDictionary *currentPDef;
@property (nonatomic, readwrite, retain) BAExpressionTree *currentPExpr;
@end

@implementation ContentService

@synthesize currentPDef;
@synthesize currentPExpr;

// Designated initializer
-(id)initWithProblemPipeline:(NSString*)source
{
    self = [super init];
    if (self)
    {
        [[CouchModelFactory sharedInstance] registerClass:[Problem class] forDocumentType:@"problem"];
        [[CouchModelFactory sharedInstance] registerClass:[Element class] forDocumentType:@"element"];
        [[CouchModelFactory sharedInstance] registerClass:[Module class] forDocumentType:@"module"];
        [[CouchModelFactory sharedInstance] registerClass:[Topic class] forDocumentType:@"topic"];
        [[CouchModelFactory sharedInstance] registerClass:[Syllabus class] forDocumentType:@"syllabus"];
        [[CouchModelFactory sharedInstance] registerClass:[ProblemAttempt class] forDocumentType:@"problem attempt"];
        
        useTestPipeline = ![@"DATABASE" isEqualToString:source];
        
        if (useTestPipeline)
        {
            currentPIndex = NSUIntegerMax;
            testProblemList = [[NSArray arrayWithContentsOfFile:BUNDLE_FULL_PATH(source)] retain];
        }
    }
    return self;
}

-(id)init
{
    return [self initWithProblemPipeline:@"DATABASE"];
}

-(void)gotoNextProblem
{
    self.currentPDef = nil;
    self.currentPExpr = nil;
    
    if (useTestPipeline)
    {
        currentPIndex = (currentPIndex == NSUIntegerMax) ? 0 : (currentPIndex + 1) % [testProblemList count];
        self.currentPDef = [NSDictionary dictionaryWithContentsOfFile:BUNDLE_FULL_PATH([testProblemList objectAtIndex:currentPIndex])];
        
        NSString *exprFile = [self.currentPDef objectForKey:EXPRESSION_FILE];
        if (exprFile)
        {
            self.currentPExpr = [BATio loadTreeFromMathMLFile:BUNDLE_FULL_PATH(exprFile)];
        }
        
    }
}

- (void)dealloc
{
    [currentPDef release];
    [currentPExpr release];
    [testProblemList release];
    [super dealloc];
}

@end
