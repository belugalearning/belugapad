//
//  ContentService.m
//  belugapad
//
//  Created by Nicholas Cartwright on 17/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ContentService.h"
#import "UsersService.h"
#import "global.h"
#import "AppDelegate.h"
#import "BAExpressionHeaders.h"
#import "BATio.h"
#import "Problem.h"
#import "ConceptNode.h"
#import "Pipeline.h"
#import "FMDatabase.h"
#import "JSONKit.h"

@interface ContentService()
{
@private
    BOOL useTestPipeline;
    
    NSArray *testProblemList;
    NSUInteger currentPIndex;
    
    FMDatabase *contentDatabase;

    //kcm concept node pipeline progression
    int pipelineIndex;

}

@property (nonatomic, readwrite, retain) Problem *currentProblem;
@property (nonatomic, readwrite, retain) NSDictionary *currentPDef;
@property (nonatomic, readwrite, retain) NSString *pathToTestDef;
@property (nonatomic, readwrite, retain) Pipeline *currentPipeline;

@end

@implementation ContentService

@synthesize currentProblem;
@synthesize currentPDef;
@synthesize currentStaticPdef;
@synthesize pathToTestDef;
@synthesize fullRedraw;
@synthesize currentPipeline;

@synthesize lightUpProgressFromLastNode;
@synthesize currentNode;

// Designated initializer
-(id)initWithProblemPipeline:(NSString*)source
{
    self = [super init];
    if (self)
    {
        useTestPipeline = ![@"DATABASE" isEqualToString:source];
        
        if (useTestPipeline)
        {
            if([source rangeOfString:@".plist"].location!=NSNotFound)
            {
                //load from this array
                currentPIndex = NSUIntegerMax;
                testProblemList = [[NSArray arrayWithContentsOfFile:BUNDLE_FULL_PATH(source)] retain];
            }
            else {
                //build an array from this location
                currentPIndex = NSUIntegerMax;
                NSString *pathOfProblems=BUNDLE_FULL_PATH(source);
                NSArray *files=[[NSFileManager defaultManager] contentsOfDirectoryAtPath:pathOfProblems error:nil];
                
                NSMutableArray *allFilePaths=[[NSMutableArray alloc] init];
                
                for (int i=0; i<files.count; i++) {
                    [allFilePaths addObject:[pathOfProblems stringByAppendingPathComponent:[files objectAtIndex:i]]];
                }
                
                testProblemList=[NSArray arrayWithArray:allFilePaths];
                [testProblemList retain];
            }

        }
        else
        {
            contentDatabase = [FMDatabase databaseWithPath:BUNDLE_FULL_PATH(@"/canned-dbs/canned-content/content.db")];
            [contentDatabase retain];
        }
    }
    return self;
}

-(void)setCurrentStaticPdef:(NSMutableDictionary*)pdef
{
    NSLog(@"setting currentStaticPdef");
    if (pdef) [pdef retain];
    if (currentStaticPdef) [currentStaticPdef release];
    currentStaticPdef = pdef;
}

-(BOOL)isUsingTestPipeline
{
    return useTestPipeline;
}

-(id)init
{
    return [self initWithProblemPipeline:@"DATABASE"];
}

-(NSArray*)allConceptNodes
{
    NSMutableArray *nodes=[[[NSMutableArray alloc] init] autorelease];
    [contentDatabase open];
    FMResultSet *rs = [contentDatabase executeQuery:@"select * from ConceptNodes"];
    while([rs next])
    {
        ConceptNode *n = [[[ConceptNode alloc] initWithFMResultSetRow:rs] autorelease];
        [nodes addObject:n];
    }
    [rs close];
    [contentDatabase close];
    return nodes;
}
    
-(NSArray*)relationMembersForName:(NSString *)name
{
    [contentDatabase open];
    FMResultSet *rs = [contentDatabase executeQuery:@"select members from BinaryRelations where name=?", name];
    NSArray *pairs = nil;
    if ([rs next])
    {
        pairs = [[rs stringForColumn:@"members"] objectFromJSONString];
    }
    [rs close];
    [contentDatabase close];
    return pairs;
}

-(Pipeline*)pipelineWithId:(NSString*)plId
{
    Pipeline *pl = nil;
    [contentDatabase open];
    FMResultSet *rs = [contentDatabase executeQuery:@"select * from Pipelines where id=?", plId];
    if ([rs next])
    {
        pl = [[[Pipeline alloc] initWithFMResultSetRow:rs] autorelease];
    }
    [rs close];
    [contentDatabase close];
    return pl;
}

-(void)startPipelineWithId:(NSString*)pipelineid forNode:(ConceptNode*)node
{
    if (![node.pipelines containsObject:pipelineid])
    {
        // TODO: Discuss with G
        NSLog(@"ContentService#startPipelineWithId error. Node id=\"%@\" doesn't contain pipeline id=\"%@\"", node._id, pipelineid);
    }
    
    [contentDatabase open];
    FMResultSet *rs = [contentDatabase executeQuery:@"select * from Pipelines where id=?", pipelineid];
    if (![rs next])
    {
        // TODO: Discuss with G
        NSLog(@"ContentService#startPipelineWithId error. Pipeline id=\"%@\" not found on database", pipelineid);
    }    
    self.currentPipeline = [[[Pipeline alloc] initWithFMResultSetRow:rs] autorelease];
    [rs close];
    [contentDatabase close];
    
    pipelineIndex=-1;
        
    self.currentNode=node;
    
    NSLog(@"starting pipeline id=\"%@\" and name=\"%@\" with %d problems", self.currentPipeline._id, self.currentPipeline.name, self.currentPipeline.problems.count);
}

-(void)quitPipelineTracking
{
    self.currentPDef=nil;
    self.currentStaticPdef = nil;
}

-(void)gotoNextProblemInPipeline
{
    pipelineIndex++;
    self.currentPDef=nil;
    
    if (useTestPipeline)
    {
        currentPIndex = (currentPIndex == NSUIntegerMax) ? 0 : (currentPIndex + 1) % [testProblemList count];
        
        NSString *problemPath=[testProblemList objectAtIndex:currentPIndex];
        
        if([problemPath rangeOfString:@".app"].location==NSNotFound)
            problemPath=BUNDLE_FULL_PATH(problemPath);
        
        self.currentPDef = [NSDictionary dictionaryWithContentsOfFile:problemPath];
        
        self.pathToTestDef=[testProblemList objectAtIndex:currentPIndex];
        NSLog(@"loaded test def: %@", self.pathToTestDef);        
    }    
    else if(pipelineIndex>=self.currentPipeline.problems.count)
    {
        //don't progress, current pdef & ppexpr are set to nil above
    }
    else
    {
        NSString *pId = [self.currentPipeline.problems objectAtIndex:pipelineIndex];
        
        [contentDatabase open];
        FMResultSet *rs = [contentDatabase executeQuery:@"select id, rev from Problems where id=?", pId];
        if (![rs next])
        {
            // TODO: Discuss with G
            NSLog(@"ContentService#gotoNextProblemInPipeline error. Problem id=\"%@\" not found on database", pId);
        }
        self.currentProblem = [[[Problem alloc] initWithFMResultSetRow:rs] autorelease];
        [rs close];
        [contentDatabase close];
        
        NSString *relPath = [NSString stringWithFormat:@"/canned-dbs/canned-content/pdefs/%@.plist", pId];
        self.currentPDef = [NSDictionary dictionaryWithContentsOfFile:BUNDLE_FULL_PATH(relPath)];
        
        if (!self.currentPDef)
        {
            // TODO: Discuss with G
            NSLog(@"self.currentPDef == nil. pdefpath:\"%@\"", relPath);
        }
    }
}

-(void)setPipelineNodeComplete
{
    NSLog(@"ContentService#setPipelineNodeComplete currentNode id=\"%@\"", currentNode._id);
    //effective placeholder for assessed complete -- e.g. lit on node
    UsersService *us = ((AppController*)[[UIApplication sharedApplication] delegate]).usersService;    
    [us addCompletedNodeId:self.currentNode._id];
}

- (void)dealloc
{
    if (contentDatabase)
    {
        [contentDatabase close];
        [contentDatabase release];
    }
    if (currentProblem) [currentProblem release];
    if (currentPDef) [currentPDef release];
    if (testProblemList) [testProblemList release];
    [super dealloc];
}

@end
