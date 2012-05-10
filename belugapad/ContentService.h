//
//  ContentService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 17/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BAExpressionTree, Problem, Syllabus, Element;
@class CouchDatabase;
@class ConceptNode;

@interface ContentService : NSObject

@property (nonatomic, retain) Element *currentElement;
@property (nonatomic, readonly, retain) Problem *currentProblem;
@property (nonatomic, readonly, retain) NSDictionary *currentPDef;
@property (nonatomic, readonly, retain) BAExpressionTree *currentPExpr;
@property (nonatomic, readonly, retain) Syllabus *defaultSyllabus;
@property BOOL fullRedraw;
@property BOOL lightUpProgressFromLastNode;
@property (nonatomic, retain) ConceptNode *currentNode;

-(id)initWithProblemPipeline:(NSString*)source;
-(void)gotoNextProblem;
-(void)setPipelineNodeComplete;


-(void)startPipelineWithId:(NSString *)pipelineid forNode:(ConceptNode*)node;
-(void)gotoNextProblemInPipeline;

-(CouchDatabase*)Database;
-(void)gotoNextProblemInElement;
-(NSArray*)allConceptNodes;
-(NSArray*)relationMembersForName:(NSString *)name;


@end
