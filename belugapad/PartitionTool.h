//
//  PartitionTool.h
//  belugapad
//
//  Created by David Amphlett on 29/03/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "ToolConsts.h"
#import "ToolScene.h"

@class DWPartitionObjectGameObject;
@class DWPartitionRowGameObject;
@class DWPartitionStoreGameObject;

@interface PartitionTool : ToolScene
{
    ToolHost *toolHost;
    DWGameWorld *gw;
    NSDictionary *problemDef;
    
    CGPoint winL;
    float cx, cy, lx, ly;

    BOOL isTouching;
    
    CCLayer *renderLayer;
    
    NSArray *initBars;
    NSArray *initObjects;
    NSArray *initCages;
    NSArray *solutionsDef;
    BOOL useBlockScaling;
    
    NSMutableArray *createdRows;
    NSMutableArray *mountedObjects;
    
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    ProblemEvalMode evalMode;
    
    float timeSinceInteractionOrShake;
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    
    BOOL hasMovedBlock;
    BOOL hasUsedBlock;
    int numberToStack;
    
    BOOL hasEvalTarget;
    int explicitEvalTarget;
    
    DWPartitionRowGameObject *previousMount;
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)populateGW;
-(void)reorderMountedObjects;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(BOOL)evalExpression;
-(void)evalProblem;
-(void)resetProblemFromReject;
@end
