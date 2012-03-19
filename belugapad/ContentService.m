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
