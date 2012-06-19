//
//  ContentService.h
//  belugapad
//
//  Created by Nicholas Cartwright on 17/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BAExpressionTree, Pipeline, Problem;
@class ConceptNode;

@interface ContentService : NSObject

@property (nonatomic, readonly, retain) Problem *currentProblem;
@property (nonatomic, readonly, retain) NSDictionary *currentPDef;
@property (nonatomic, retain) NSMutableDictionary *currentStaticPdef;
@property (nonatomic, readonly, retain) NSString *pathToTestDef;
@property (nonatomic, readonly, retain) Pipeline *currentPipeline;
@property BOOL fullRedraw;
@property BOOL lightUpProgressFromLastNode;
@property (nonatomic, retain) ConceptNode *currentNode;

-(id)initWithProblemPipeline:(NSString*)source;
-(void)setPipelineNodeComplete;
-(BOOL)isUsingTestPipeline;

-(BOOL) createAndStartFunnelForNode:(NSString*)nodeId;

-(void)startPipelineWithId:(NSString*)pipelineid forNode:(ConceptNode*)node;
-(void)gotoNextProblemInPipeline;

-(NSArray*)allConceptNodes;
-(ConceptNode*)conceptNodeForId:(NSString*)nodeId;
-(NSArray*)relationMembersForName:(NSString*)name;
-(Pipeline*)pipelineWithId:(NSString*)plId;

-(void)quitPipelineTracking;

@end
