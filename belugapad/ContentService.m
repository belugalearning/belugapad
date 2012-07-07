//
//  ContentService.m
//  belugapad
//
//  Created by Nicholas Cartwright on 17/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ContentService.h"
#import "UsersService.h"
#import "LoggingService.h"
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
    
    // local test pipeline
    NSArray *testProblemList;
    NSUInteger currentPIndex;
    
    // kcm database pipelines
    FMDatabase *contentDatabase;
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

@synthesize resetPositionAfterTH;
@synthesize lastMapLayerPosition;

@synthesize lightUpProgressFromLastNode;
@synthesize currentNode;

#pragma mark - init and setup

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
                
                [allFilePaths release];
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

#pragma mark - dynamic pipeline creation

-(BOOL) createAndStartFunnelForNode:(NSString*)nodeId
{
    //get node by id
    ConceptNode *n=[self conceptNodeForId:nodeId];
    
    if(n.mastery)
    {
        UsersService *us = ((AppController*)[[UIApplication sharedApplication] delegate]).usersService;    
        
        //step over child nodes and look for one that's not completed, if found start it's pipeline
        NSMutableArray *children=[self childNodesForMasteryWithId:nodeId];
        
        if(children.count==0)
        {
            NSLog(@"there are no children here");
            return NO;
        }
        
        for (ConceptNode *child in children) {
            if(![us hasCompletedNodeId:child._id])
            {
                if(child.pipelines.count>0)
                {
                    [self startPipelineWithId:[child.pipelines objectAtIndex:0] forNode:child];
                    
                    return YES;
                }
            }
        }
        
        //pick random child
        int ip=arc4random()%children.count;
        
        
        ConceptNode *child=[children objectAtIndex:ip];
    
        if(child.pipelines.count>0)
        {
            [self startPipelineWithId:[child.pipelines objectAtIndex:0] forNode:child];
            return YES;
        }
        else {
            NSLog(@"selected child doesn't have a pipeline");
        }
        
        return NO;
    }
    
    else {
        //if node (incomplete) do same
        
        //if node (and that node is complete) funnel is that node's pipeline
    
        //todo: fake it -- direct to node for now
        if(n.pipelines.count>0)
        {
            [self startPipelineWithId:[n.pipelines objectAtIndex:0] forNode:n];
            return YES;
        }
        else {
            NSLog(@"no pipeline found for node %@", nodeId);
            return NO;
        }
    }
}


#pragma mark - data access

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

-(ConceptNode*)conceptNodeForId:(NSString*)nodeId
{
    [contentDatabase open];
    ConceptNode *returnNode=nil;
    FMResultSet *rs=[contentDatabase executeQuery:@"select * from ConceptNodes where id=?", nodeId];
    if([rs next])
    {
        returnNode=[[[ConceptNode alloc] initWithFMResultSetRow:rs] autorelease];
    }
    else {
        NSLog(@"ConceptNode with id %@ not found", nodeId);
    }
    [rs close];
    [contentDatabase close];
    return returnNode;
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

-(NSMutableArray*)childNodesForMasteryWithId:(NSString*)masteryId
{
    NSMutableArray *ret=[[[NSMutableArray alloc] init] autorelease];
    
    NSArray *rel=[self relationMembersForName:@"Mastery"];
    
    for (NSArray *pair in rel) {
        if ([[pair objectAtIndex:1] isEqualToString:masteryId]) {
            [ret addObject:[self conceptNodeForId:[pair objectAtIndex:0]]];
        }
    }
    
    return ret;
}

-(NSArray*)allRegions
{
    [contentDatabase open];
    NSMutableArray *regions=[[NSMutableArray alloc] init];
    
    FMResultSet *rs=[contentDatabase executeQuery:@"select distinct region from conceptnodes"];
    
    while ([rs next]) {
        NSArray *rlist=[[rs stringForColumn:@"region"] objectFromJSONString];
        if(rlist.count>0)
            if(![[rlist objectAtIndex:0] isEqualToString:@""])
                [regions addObject:[rlist objectAtIndex:0]];
    }
    
    [rs close];
    [contentDatabase close];

    NSArray *ret=[NSArray arrayWithArray:regions];
    [regions release];
    return ret;
}


#pragma mark - the rest

-(void)setCurrentStaticPdef:(NSMutableDictionary*)pdef
{
    NSLog(@"setting currentStaticPdef");
    if (pdef) [pdef retain];
    //if (currentStaticPdef) [currentStaticPdef release];
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

-(void)startPipelineWithId:(NSString*)pipelineid forNode:(ConceptNode*)node
{
    if (![node.pipelines containsObject:pipelineid])
    {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setValue:BL_APP_ERROR_TYPE_BAD_ARG forKey:@"type"];
        [d setValue:@"ContentService#startPipelineWithId" forKey:@"method"];
        [d setValue:node._id forKey:@"nodeId"];
        [d setValue:pipelineid forKey:@"pipelineId"];
        [d setValue:@"node does contain pipelineid" forKey:@"description"];        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        [ac.loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
    }
    
    [contentDatabase open];
    FMResultSet *rs = [contentDatabase executeQuery:@"select * from Pipelines where id=?", pipelineid];
    if (![rs next])
    {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        [d setValue:BL_APP_ERROR_TYPE_DB_TABLE_MISSING_ROW forKey:@"type"];
        [d setValue:@"Pipelines" forKey:@"table"];
        [d setValue:pipelineid forKey:@"key"];        
        AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
        [ac.loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
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
    else if(++pipelineIndex>=self.currentPipeline.problems.count)
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
            NSMutableDictionary *d = [NSMutableDictionary dictionary];
            [d setValue:BL_APP_ERROR_TYPE_DB_TABLE_MISSING_ROW forKey:@"type"];
            [d setValue:@"Problems" forKey:@"table"];
            [d setValue:pId forKey:@"key"];        
            AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
            [ac.loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
        }
        self.currentProblem = [[[Problem alloc] initWithFMResultSetRow:rs] autorelease];
        [rs close];
        [contentDatabase close];
        
        NSString *relPath = [NSString stringWithFormat:@"/canned-dbs/canned-content/pdefs/%@.plist", pId];
        self.currentPDef = [NSDictionary dictionaryWithContentsOfFile:BUNDLE_FULL_PATH(relPath)];
        
        if (!self.currentPDef)
        {
            NSMutableDictionary *d = [NSMutableDictionary dictionary];
            [d setValue:BL_APP_ERROR_TYPE_MISSING_PDEF forKey:@"type"];
            [d setValue:pId forKey:@"problemId"];
            [d setValue:relPath forKey:@"path"];
            AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
            [ac.loggingService logEvent:BL_APP_ERROR withAdditionalData:d];
        }
    }
}

-(void)setPipelineNodeComplete
{
    if (useTestPipeline) return;
    
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
