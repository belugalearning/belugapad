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
#import "Element.h"
#import "Module.h"
#import "Topic.h"
#import "Syllabus.h"
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
    ConceptNode *currentNode;
}

@property (nonatomic, readwrite, retain) Problem *currentProblem;
@property (nonatomic, readwrite, retain) NSDictionary *currentPDef;
@property (nonatomic, readwrite, retain) BAExpressionTree *currentPExpr;
@property (nonatomic, readwrite, retain) Syllabus *defaultSyllabus;

@end

@implementation ContentService

@synthesize currentElement;
@synthesize currentProblem;
@synthesize currentPDef;
@synthesize currentPExpr;
@synthesize defaultSyllabus;
@synthesize fullRedraw;

-(void)setCurrentElement:(Element*)element
{
    self.currentProblem = nil;
    if (currentElement) [currentElement release];
    currentElement = [element retain];
}

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
            [[CouchModelFactory sharedInstance] registerClass:[Element class] forDocumentType:@"element"];
            [[CouchModelFactory sharedInstance] registerClass:[Module class] forDocumentType:@"module"];
            [[CouchModelFactory sharedInstance] registerClass:[Topic class] forDocumentType:@"topic"];
            [[CouchModelFactory sharedInstance] registerClass:[Syllabus class] forDocumentType:@"syllabus"];
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
            NSArray *syllabi = q.rows.allObjects; // there should be exactly 1
            
            if ([syllabi count] > 0)
            {
                self.defaultSyllabus = [[CouchModelFactory sharedInstance] modelForDocument:((CouchQueryRow*)[syllabi objectAtIndex:0]).document];
            }
            
            // TODO: REINSTATE REPLICATION - will need to manage response to changes in remote content database
            //pullReplication = [[database pullFromDatabaseAtURL:[NSURL URLWithString:kRemoteContentDatabaseURI]] retain];
            //pullReplication.continuous = YES;
        }
    }
    return self;
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
    
    currentNode=node;
    [currentNode retain];
    
    NSLog(@"starting pipeline named %@ with %d problems", currentPipeline.name, currentPipeline.problems.count);
}

-(void)gotoNextProblemInPipeline
{
    pipelineIndex++;
    self.currentPDef=nil;
    self.currentPExpr=nil;
    
    if(pipelineIndex>=currentPipeline.problems.count)
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
    [us addCompletedNodeId:currentNode.document.documentID];
    
    //NSLog(@"currentNode: %@", currentNode.document.documentID);
}

-(void)gotoNextProblemInElement
{
    self.currentPDef = nil;
    self.currentPExpr = nil;
    
    if (!self.currentElement)
    {
        self.currentProblem = nil;
        
        NSString *tId = [self.defaultSyllabus.topics objectAtIndex:0];
        Topic *t = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:tId]];
        
        NSString *mId = [t.modules objectAtIndex:0];
        Module *m = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:mId]];
        
        NSString *eId = [m.elements objectAtIndex:0];
        self.currentElement = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:eId]];
        
    }
    else if (self.currentProblem && ![self.currentProblem.elementId isEqualToString:self.currentElement.document.documentID])
    {
        self.currentProblem = nil;        
    }
    
    NSUInteger pIx = 0;
    if (self.currentProblem)
    {
        pIx = 1 + [self.currentElement.includedProblems indexOfObject:self.currentProblem.document.documentID];
    }
    
    if (pIx < [self.currentElement.includedProblems count])
    {
        NSString *pId = [self.currentElement.includedProblems objectAtIndex:pIx];
        self.currentProblem = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:pId]];
        self.currentPDef = self.currentProblem.pdef;
        NSData *expressionData = self.currentProblem.expressionData;
        if (expressionData) self.currentPExpr = [BATio loadTreeFromMathMLData:expressionData];
    }
    else
    {
        self.currentProblem = nil;
    }
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
    else
    {
        NSUInteger tIx = 0;
        NSUInteger mIx = 0;
        NSUInteger eIx = 0;
        NSUInteger pIx = 0;
        
        if (self.currentProblem)
        {
            Topic *t = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:self.currentProblem.topicId]];
            Module *m = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:self.currentProblem.moduleId]];
            Element *e = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:self.currentProblem.elementId]];
            
            tIx = [self.defaultSyllabus.topics indexOfObject:self.currentProblem.topicId];
            mIx = [t.modules indexOfObject:self.currentProblem.moduleId];
            eIx = [m.elements indexOfObject:self.currentProblem.elementId];
            pIx = 1 + [e.includedProblems indexOfObject:self.currentProblem.document.documentID];
            
            self.currentProblem = nil;
        }
        
        while (!self.currentProblem && tIx < [self.defaultSyllabus.topics count])
        {
            NSString *tId = [self.defaultSyllabus.topics objectAtIndex:tIx];
            Topic *t = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:tId]];
            
            while (!self.currentProblem && mIx < [t.modules count])
            {
                NSString *mId = [t.modules objectAtIndex:mIx];
                Module *m = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:mId]];
                
                while (!self.currentProblem && eIx < [m.elements count])
                {
                    NSString *eId = [m.elements objectAtIndex:eIx];
                    Element *e = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:eId]];
                    
                    if (pIx < [e.includedProblems count])
                    {
                        NSString *pId = [e.includedProblems objectAtIndex:pIx];
                        self.currentProblem = [[CouchModelFactory sharedInstance] modelForDocument:[database documentWithID:pId]];
                    }
                    else
                    {
                        pIx = 0;
                        ++eIx;
                    }
                }
                eIx = 0;           
                ++mIx;
            }            
            ++tIx;
        }
        
        if (self.currentProblem)
        {
            self.currentPDef = self.currentProblem.pdef;
            NSData *expressionData = self.currentProblem.expressionData;
            if (expressionData) self.currentPExpr = [BATio loadTreeFromMathMLData:expressionData];
        }
    }
}

- (void)dealloc
{
    [currentPDef release];
    [currentPExpr release];
    [testProblemList release];
    [self.defaultSyllabus release];
    [pullReplication release];
    [super dealloc];
}

@end
