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
#import "Relation.h"
#import "Pipeline.h"
#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchDesignDocument_Embedded.h>
#import <CouchCocoa/CouchModelFactory.h>

//NSString * const kRemoteContentDatabaseURI = @"http://u.zubi.me:5984/temp-blm-content";
NSString * const kRemoteContentDatabaseURI = @"http://u.zubi.me:5984/please-do-not-replicate-me";
NSString * const kLocalContentDatabaseName = @"kcm";
NSString * const kDefaultContentDesignDocName = @"kcm-views";

@interface ContentService()
{
@private
    BOOL useTestPipeline;    
    
    NSArray *testProblemList;
    NSUInteger currentPIndex;
    
    CouchDatabase *database;

    // TODO: Need way to figure out when replication is complete. 
    // TODO: not sure about this - using TOUCHDB, with logging turned on, building to simulator, took 3 runs to get db updated to latest sequence number.
    //      Does this mean continuous replication not reliable? Or is it the simulator? Or....?
    // Try using comparison of database.lastSequenceNumber against http://u.zubi.me:5984/temp-blm-content doc's update_seq value
    CouchReplication *pullReplication;
    
    //kcm concept node pipeline progression
    int pipelineIndex;
    
    NSString *NodeIdCopy;

}

@property (nonatomic, readwrite, retain) Problem *currentProblem;
@property (nonatomic, readwrite, retain) NSDictionary *currentPDef;
@property (nonatomic, readwrite, retain) BAExpressionTree *currentPExpr;
@property (nonatomic, readwrite, retain) NSString *pathToTestDef;
@property (nonatomic, readwrite, retain) Pipeline *currentPipeline;

@end

@implementation ContentService

@synthesize currentProblem;
@synthesize currentPDef;
@synthesize currentStaticPdef;
@synthesize pathToTestDef;
@synthesize currentPExpr;
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
            [[CouchModelFactory sharedInstance] registerClass:[Problem class] forDocumentType:@"problem"];
            [[CouchModelFactory sharedInstance] registerClass:[ConceptNode class] forDocumentType:@"concept node"];
            [[CouchModelFactory sharedInstance] registerClass:[Relation class] forDocumentType:@"relation"];
            [[CouchModelFactory sharedInstance] registerClass:[Pipeline class] forDocumentType:@"pipeline"];
            
            CouchEmbeddedServer *server = [CouchEmbeddedServer sharedInstance];
            
            database = [server databaseNamed:kLocalContentDatabaseName];
            RESTOperation* op = [database create];
            if (![op wait] && op.error.code != 412)
            {
                self = nil;
                return self;
            }            
            database.tracksChanges = YES;
        }
    }
    return self;
}

-(void)setCurrentStaticPdef:(NSMutableDictionary *)currentStaticPdefValue
{
    NSLog(@"setting currentStaticPdef");
    [currentStaticPdefValue retain];
    //[currentStaticPdef release];
    currentStaticPdef=currentStaticPdefValue;
}

-(BOOL)isUsingTestPipeline
{
    return useTestPipeline;
}

-(CouchDatabase*)Database
{
    return database;
}

-(id)init
{
    return [self initWithProblemPipeline:@"DATABASE"];
}

-(NSArray*)allConceptNodes
{
    CouchQuery *nodeq=[[database designDocumentWithName:kDefaultContentDesignDocName] queryViewNamed:@"concept-nodes"];
    [[nodeq start] wait];
    
    NSArray *ids=nodeq.rows.allObjects;
    
    NSMutableArray *nodes=[[NSMutableArray alloc] init];
    for (int i=0; i<[ids count]; i++) {
        CouchQueryRow *qr=[ids objectAtIndex:i];
        NSString *thisid=qr.key;
        ConceptNode *n=[[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:thisid]];
        
        [nodes addObject:n];
    }
    return nodes;
}

-(NSArray*)relationMembersForName:(NSString *)name
{
    CouchQuery *rq=[[database designDocumentWithName:kDefaultContentDesignDocName] queryViewNamed:@"relations-by-name"];
    rq.prefetch=YES;
    [[rq start] wait];
    
    for (CouchQueryRow *qr in rq.rows) {
        
        if([qr.key isEqualToString:@"Prerequisite"])
        {
            Relation *r=[[CouchModelFactory sharedInstance] modelForDocument:qr.document];
            return r.members;
        }
    }
    return nil;
}

-(void)startPipelineWithId:(NSString *)pipelineid forNode:(ConceptNode*)node
{
    if(self.currentPipeline) [self.currentPipeline release];
    
    self.currentPipeline=[[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:pipelineid]];
    [self.currentPipeline retain];
    pipelineIndex=-1;
    
    
    
    self.currentNode=node;
    [self.currentNode retain];
    
    NodeIdCopy=[currentNode.document.documentID copy];
    
    NSLog(@"starting pipeline named %@ with %d problems", self.currentPipeline.name, self.currentPipeline.problems.count);
}

-(void)quitPipelineTracking
{
    self.currentPDef=nil;
    self.currentPExpr=nil;
    [self.currentStaticPdef release];
}

-(void)gotoNextProblemInPipeline
{
    pipelineIndex++;
    self.currentPDef=nil;
    self.currentPExpr=nil;
    
    if (useTestPipeline)
    {
        currentPIndex = (currentPIndex == NSUIntegerMax) ? 0 : (currentPIndex + 1) % [testProblemList count];
        
        NSString *problemPath=[testProblemList objectAtIndex:currentPIndex];
        
        if([problemPath rangeOfString:@".app"].location==NSNotFound)
            problemPath=BUNDLE_FULL_PATH(problemPath);
        
        self.currentPDef = [NSDictionary dictionaryWithContentsOfFile:problemPath];
        
        self.pathToTestDef=[testProblemList objectAtIndex:currentPIndex];
        NSLog(@"loaded test def: %@", self.pathToTestDef);
        
        NSString *exprFile = [self.currentPDef objectForKey:EXPRESSION_FILE];
        if (exprFile)
        {
            self.currentPExpr = [BATio loadTreeFromMathMLFile:BUNDLE_FULL_PATH(exprFile)];
        }
        
    }    
    else if(pipelineIndex>=self.currentPipeline.problems.count)
    {
        //don't progress, current pdef & ppexpr are set to nil above
    }
    else {
        NSString *pid=[self.currentPipeline.problems objectAtIndex:pipelineIndex];
        self.currentProblem = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:pid]];
        self.currentPDef = self.currentProblem.pdef;
        NSData *expressionData = self.currentProblem.expressionData;
        if (expressionData) self.currentPExpr = [BATio loadTreeFromMathMLData:expressionData];
    }
}

-(void)setPipelineNodeComplete
{
    //effective placeholder for assessed complete -- e.g. lit on node
    
    NSLog(@"node id: %@", NodeIdCopy);
    NSLog(@"currentNode id %@", currentNode.document.documentID);
    
    UsersService *us = ((AppController*)[[UIApplication sharedApplication] delegate]).usersService;

    NSLog(@"currentNode id %@", currentNode.document.documentID);
    
    [us addCompletedNodeId:NodeIdCopy];
    
    NSLog(@"currentNode id %@", currentNode.document.documentID);
    
    if ([us hasCompletedNodeId:NodeIdCopy])
    {
        NSLog(@"user completed node");
    }
    
    
//      if (currentNode)
//    {
//        [us addCompletedNodeId:currentNode.document.documentID];
//    }
    
    //NSLog(@"currentNode: %@", currentNode.document.documentID);
}

- (void)dealloc
{
    [currentPDef release];
    [currentPExpr release];
    [testProblemList release];
    [pullReplication release];
    [super dealloc];
}

@end
