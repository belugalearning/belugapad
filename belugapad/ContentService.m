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

NSString * const kRemoteContentDatabaseURI = @"http://www.soFarAslant.com:5984/temp-blm-content";
NSString * const kLocalContentDatabaseName = @"content";
NSString * const kDefaultDesignDocName = @"default";
NSString * const kDefaultSyllabusViewName = @"default-syllabus";

@interface ContentService()
{
@private
    BOOL useTestPipeline;    
    
    NSArray *testProblemList;
    NSUInteger currentPIndex;
    
    CouchDatabase *database;
    Problem *currentProblem;
}

@property (nonatomic, readwrite, retain) NSDictionary *currentPDef;
@property (nonatomic, readwrite, retain) BAExpressionTree *currentPExpr;

-(void)createViews;
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
        else
        {
            [[CouchModelFactory sharedInstance] registerClass:[Problem class] forDocumentType:@"problem"];
            [[CouchModelFactory sharedInstance] registerClass:[Element class] forDocumentType:@"element"];
            [[CouchModelFactory sharedInstance] registerClass:[Module class] forDocumentType:@"module"];
            [[CouchModelFactory sharedInstance] registerClass:[Topic class] forDocumentType:@"topic"];
            [[CouchModelFactory sharedInstance] registerClass:[Syllabus class] forDocumentType:@"syllabus"];
            
            CouchTouchDBServer *server = [CouchTouchDBServer sharedInstance];
            database = [server databaseNamed:kLocalContentDatabaseName];
            RESTOperation* op = [database create];
            if (![op wait] && op.error.code != 412)
            {
                self = nil;
                return self;
            }
            database.tracksChanges = YES;
            
            CouchReplication *pull;
            pull = [[database pullFromDatabaseAtURL:[NSURL URLWithString:kRemoteContentDatabaseURI]] retain];
            [[pull start] wait];
            [pull release];
            
            [self createViews];
            
            CouchQuery *q = [[database designDocumentWithName:kDefaultDesignDocName] queryViewNamed:kDefaultSyllabusViewName];
            [[q start] wait];            
            return [[CouchModelFactory sharedInstance] modelForDocument:((CouchQueryRow*)[q.rows.allObjects objectAtIndex:0]).document];
            
            
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
    else
    {
        if (currentProblem) [currentProblem release];
    }
}

-(void)createViews
{
    CouchDesignDocument* design = [database designDocumentWithName:kDefaultDesignDocName];
    
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
    [super dealloc];
}

@end
