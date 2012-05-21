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
    Pipeline *currentPipeline;
    int pipelineIndex;
//    ConceptNode *currentNode;
}

@property (nonatomic, readwrite, retain) Problem *currentProblem;
@property (nonatomic, readwrite, retain) NSDictionary *currentPDef;
@property (nonatomic, readwrite, retain) BAExpressionTree *currentPExpr;

@end

@implementation ContentService

@synthesize currentProblem;
@synthesize currentPDef;
@synthesize currentStaticPdef;
@synthesize currentPExpr;
@synthesize fullRedraw;

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
            currentPIndex = NSUIntegerMax;
            testProblemList = [[NSArray arrayWithContentsOfFile:BUNDLE_FULL_PATH(source)] retain];
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
            
            CouchQuery *q = [[database designDocumentWithName:kDefaultContentDesignDocName] queryViewNamed:@"syllabi-by-name"];
            q.keys = [NSArray arrayWithObject:@"Default"];
            [[q start] wait];
            
            // TODO: REINSTATE REPLICATION - will need to manage response to changes in remote content database
            //pullReplication = [[database pullFromDatabaseAtURL:[NSURL URLWithString:kRemoteContentDatabaseURI]] retain];
            //pullReplication.continuous = YES;
        }
    }
    return self;
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
    if(currentPipeline) [currentPipeline release];
    
    currentPipeline=[[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:pipelineid]];
    [currentPipeline retain];
    pipelineIndex=-1;
    
    self.currentNode=node;
    [self.currentNode retain];
    
    NSLog(@"starting pipeline named %@ with %d problems", currentPipeline.name, currentPipeline.problems.count);
}

-(void)gotoNextProblemInPipeline
{
    pipelineIndex++;
    self.currentPDef=nil;
    self.currentPExpr=nil;
    
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
    else if(pipelineIndex>=currentPipeline.problems.count)
    {
        //don't progress, current pdef & ppexpr are set to nil above
    }
    else {
        NSString *pid=[currentPipeline.problems objectAtIndex:pipelineIndex];
        self.currentProblem = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:pid]];
        self.currentPDef = self.currentProblem.pdef;
        NSData *expressionData = self.currentProblem.expressionData;
        if (expressionData) self.currentPExpr = [BATio loadTreeFromMathMLData:expressionData];
    }
}

-(void)setPipelineNodeComplete
{
    //effective placeholder for assessed complete -- e.g. lit on node
    
    UsersService *us = ((AppController*)[[UIApplication sharedApplication] delegate]).usersService;
    if (currentNode)
    {
        [us addCompletedNodeId:currentNode.document.documentID];
    }
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
