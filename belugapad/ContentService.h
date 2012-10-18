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
@property (nonatomic, readonly, retain) NSArray *currentPipeline;
@property BOOL fullRedraw;
@property BOOL lightUpProgressFromLastNode;
@property (nonatomic, retain) ConceptNode *currentNode;

@property BOOL resetPositionAfterTH;
@property CGPoint lastMapLayerPosition;

@property (readonly) int pipelineIndex;
@property (readonly) int episodeIndex;

@property (readonly) NSString *contentDir;

//episode
@property (retain) NSMutableArray *currentEpisode;
@property (readonly) BOOL isUserAtEpisodeHead;
@property (readonly) BOOL isUserPastEpisodeHead;

-(id)initWithLocalSettings:(NSDictionary*)settings;
-(void)setPipelineNodeComplete;
-(void)setPipelineScore:(int)score;
-(BOOL)isUsingTestPipeline;

-(void)updateContentDatabaseWithSettings:(NSDictionary*)settings;

-(BOOL) createAndStartFunnelForNode:(NSString*)nodeId;

-(void)startPipelineWithId:(NSString*)pipelineid forNode:(ConceptNode*)node;
-(void)gotoNextProblemInPipeline;
-(void)gotoNextProblemInPipelineWithSkip:(int)skipby;

-(NSArray*)allConceptNodes;
-(ConceptNode*)conceptNodeForId:(NSString*)nodeId;
-(NSArray*)relationMembersForName:(NSString*)name;
-(Pipeline*)pipelineWithId:(NSString*)plId;
-(NSArray*)allRegions;

-(void)quitPipelineTracking;

-(void)adaptPipelineByInsertingWithTriggerData:(NSDictionary*)triggerData;
-(NSString*)debugPipelineString;

@end
