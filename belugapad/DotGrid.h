//
//  DotGrid.h
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "ToolConsts.h"
#import "ToolScene.h"

@class DWDotGridShapeGameObject;

typedef enum {
    kAnyStartAnchorValid=0,
    kSpecifiedStartAnchor=1,
    kNoDrawing=2
} DrawMode;

typedef enum {
    kNoState=0,
    kStartAnchor=1,
    kResizeShape=2,
    kMoveShape=3
} GameState;

typedef enum {
    kProblemTotalShapeSize=0,
    kProblemSumOfFractions=1
} DotGridEvalType;

@interface DotGrid : ToolScene
{
    ToolHost *toolHost;
    DWGameWorld *gw;
    
    DrawMode drawMode;
    GameState gameState;
    ProblemEvalMode evalMode;
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    DotGridEvalType evalType;

    int evalDividend;
    int evalDivisor;
    int evalTotalSize;
    
    BOOL doNotSimplifyFractions;
    
    CGPoint winL;
    float cx, cy, lx, ly;
    
    BOOL isTouching;
    
    CCLayer *renderLayer;
    
    NSArray *initObjects;
    NSArray *solutionsDef;
    
    CGPoint lastTouch;
    
    BOOL showDraggableBlock;
    BOOL renderWidthHeightOnShape;
    BOOL selectWholeShape;
    
    CCSprite *dragBlock;
    CCSprite *newBlock;
    BOOL hitDragBlock;
    
    NSMutableArray *dotMatrix;
    NSDictionary *hiddenRows;
    
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    
    int spaceBetweenAnchors;
    int startX;
    int startY;
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)populateGW;
-(void)checkAnchors;
-(void)checkAnchorsAndUseResizeHandle:(BOOL)showResize andShowMove:(BOOL)showMove andPrecount:(NSArray*)preCountedTiles andDisabled:(BOOL)Disabled;
-(void)checkAnchorsOfExistingShape:(DWDotGridShapeGameObject*)thisShape;
-(void)createShapeWithAnchorPoints:(NSArray*)anchors andPrecount:(NSArray*)preCountedTiles andDisabled:(BOOL)Disabled;
-(void)modifyThisShape:(DWDotGridShapeGameObject*)thisShape withTheseAnchors:(NSArray*)anchors;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(BOOL)evalExpression;
-(void)evalProblem;
-(void)resetProblem;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;

@end
