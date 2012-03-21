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
#import <CouchCocoa/CouchCocoa.h>
#import <CouchCocoa/CouchDesignDocument_Embedded.h>
#import <CouchCocoa/CouchModelFactory.h>
#import <CouchCocoa/CouchTouchDBServer.h>
#import <TouchDB/TouchDB.h>

NSString * const kRemoteContentDatabaseURI = @"http://www.soFarAslant.com:5984/temp-blm-content";
NSString * const kLocalContentDatabaseName = @"content";
NSString * const kDefaultContentDesignDocName = @"default";
NSString * const kDefaultSyllabusViewName = @"default-syllabus";

@interface ContentService()
{
@private
    BOOL useTestPipeline;    
    
    NSArray *testProblemList;
    NSUInteger currentPIndex;
    
    CouchDatabase *database;

    // TODO: pull replication temporarily removed. Need way to figure out when replication is complete. 
    // TODO: not sure about this - with logging turned on, building to simulator, took 3 runs to get db updated to latest sequence number.
    //      Does this mean continuous replication not reliable? Or is it the simulator? Or....?
    // Try using comparison of database.lastSequenceNumber against http://www.sofaraslant.com:5984/temp-blm-content doc's update_seq value
    CouchReplication *pullReplication;
}

@property (nonatomic, readwrite, retain) Problem *currentProblem;
@property (nonatomic, readwrite, retain) NSDictionary *currentPDef;
@property (nonatomic, readwrite, retain) BAExpressionTree *currentPExpr;
@property (nonatomic, readwrite, retain) Syllabus *defaultSyllabus;

-(void)createViews;
@end

@implementation ContentService

@synthesize currentElement;
@synthesize currentProblem;
@synthesize currentPDef;
@synthesize currentPExpr;
@synthesize defaultSyllabus;

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
            
            CouchTouchDBServer *server = [CouchTouchDBServer sharedInstance];
            
            // if this is the first launch of the app, install canned content db                      
            TDDatabase *db = [server.touchServer databaseNamed:kLocalContentDatabaseName];
            if (!db.exists)
            {
                // first launch
                NSError *err;
                [db replaceWithDatabaseFile:BUNDLE_FULL_PATH(@"/canned-content-db/content.touchdb")
                            withAttachments:BUNDLE_FULL_PATH(@"/canned-content-db/content-attachments")
                                      error:&err];
            }
            
            database = [server databaseNamed:kLocalContentDatabaseName];
            database.tracksChanges = YES;
            
            [self createViews];
            
            CouchQuery *q = [[database designDocumentWithName:kDefaultContentDesignDocName] queryViewNamed:kDefaultSyllabusViewName];
            [[q start] wait];
            NSArray *syllabi = q.rows.allObjects; // there should be exactly 1
            
            if ([syllabi count] > 0)
            {
                self.defaultSyllabus = [[CouchModelFactory sharedInstance] modelForDocument:((CouchQueryRow*)[syllabi objectAtIndex:0]).document];
            }
            
// For the moment relying soley on canned db            
//            pullReplication = [[database pullFromDatabaseAtURL:[NSURL URLWithString:kRemoteContentDatabaseURI]] retain];
//            pullReplication.continuous = YES;
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

-(void)createViews
{
    CouchDesignDocument* design = [database designDocumentWithName:kDefaultContentDesignDocName];
    
    [design defineViewNamed:kDefaultSyllabusViewName
                   mapBlock:MAPBLOCK({
        id type = [doc objectForKey:@"type"];
        id name = [doc objectForKey:@"name"];
        
        if (type && name &&
            [@"syllabus" isEqualToString:type] &&
            [@"Default" isEqualToString:name])
        {
            emit([doc objectForKey:@"_id"], nil);
        }
    })
                    version:@"v1.00"];
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
