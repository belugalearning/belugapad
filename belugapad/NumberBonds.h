//
//  NumberBonds.h
//  belugapad
//
//  Created by David Amphlett on 29/03/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "ToolConsts.h"
#import "ToolScene.h"

@class DWNBondObjectGameObject;
@class DWNBondRowGameObject;
@class DWNBondStoreGameObject;

typedef enum {
    kSolutionTopRow=0,   // solution comes from the value of the top row
    kSolutionRowMatch=1, // solution comes from the SOLUTIONS dictionary
    kSolutionFreeform=2,  // solution comes any way - so long as the rows match SOLUTION_VALUE
    kSolutionUniqueCompositionsOfTopRow=3, // all rows match top row and are unique (including top row)
    kSolutionUniqueCompositionsOfValue=4 // all rows match value and are unique
} NumberBondSolutionMode;

@interface NumberBonds : ToolScene
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
    NSArray *initHints;
    NSArray *initCages;
    NSArray *solutionsDef;
    int solutionValue;
    BOOL useBlockScaling;
    BOOL showBadgesOnCages;
    BOOL barAssistance;
    BOOL createdNewBar;
    
    int blocksForThisStore[10];
    int blocksUsedFromThisStore[10];
    int storeCanCreate[10];
    
    
    NSMutableArray *createdRows;
    NSMutableArray *mountedObjects;
    NSMutableArray *mountedObjectLabels;
    NSMutableArray *mountedObjectBadges;
    NSMutableArray *allRows;
    
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    ProblemEvalMode evalMode;
    NumberBondSolutionMode solutionMode;
    
    int evalMinPerRow;
    int evalMaxPerRow;
    int evalUniqueCopmositionTarget;
    
    float timeSinceInteractionOrShake;
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    
    BOOL hasMovedBlock;
    BOOL hasUsedBlock;
    int numberToStack;
    
    DWNBondRowGameObject *previousMount;
    DWNBondRowGameObject *repositionThis;
    DWNBondRowGameObject *repositionThat;
    
    BOOL doNotSendPositionEval;
    float timeLeftToPositionThisOne;
    float timeLeftToPositionThatOne;
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)populateGW;
-(void)updateLabels;
-(void)reorderMountedObjects;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(BOOL)evalExpression;
-(void)evalProblem;
-(void)resetProblemFromReject;
@end
