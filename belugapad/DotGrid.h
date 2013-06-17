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
@class DWDotGridShapeGroupGameObject;
@class DWDotGridAnchorGameObject;
@class DWNWheelGameObject;

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
    kProblemSumOfFractions=1,
    kProblemGridMultiplication=2,
    kProblemCheckDimensions=3,
    kProblemFactorDimensions=4,
    kProblemNonProportionalGrid=5,
    kProblemSingleShapeSize=6,
    kProblemIntroPlist=99
} DotGridEvalType;

typedef struct {
    NSArray *matchedShapes;
    NSArray *matchedGOs;
    BOOL canEval;
} CorrectSizeInfo;

typedef struct {
    DWDotGridAnchorGameObject *firstAnchor;
    DWDotGridAnchorGameObject *lastAnchor;
} OrderedAnchors;

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
    int solutionNumber;
    
    BOOL autoAddition;
    BOOL doNotSimplifyFractions;
    
    CGPoint winL;
    float cx, cy, lx, ly;
    
    BOOL isTouching;
    
    CCLayer *renderLayer;
    CCLayer *anchorLayer;
    
    NSArray *initObjects;
    NSArray *solutionsDef;
    
    NSArray *reqShapes;
    
    CGPoint lastTouch;
    
    BOOL audioHasPlayedResizing;
    
    BOOL disableDrawing;
    BOOL showDraggableBlock;
    BOOL renderWidthHeightOnShape;
    BOOL selectWholeShape;
    BOOL showNumberWheel;
    BOOL showCountBubble;
    BOOL isMovingLeft;
    BOOL isMovingRight;
    BOOL isMovingUp;
    BOOL isMovingDown;
    BOOL gridMultiCanEval;
    BOOL debugLogging;
    BOOL traceOriginalShapes;
    
    NSString *showCount;
    
    CCSprite *dragBlock;
    CCSprite *newBlock;
    CCLayer *introLayer;
    BOOL hitDragBlock;
    
    BOOL useShapeGroups;
    BOOL showMoreOrLess;
    int shapeGroupSize;
    int shapeBaseSize;
    int nonPropEvalX;
    int nonPropEvalY;
    int numberWheelComponents;
    
    
    BOOL isIntroPlist;
    BOOL hitIntroCommit;
    BOOL showingIntroOverlay;
    CCSprite *introOverlay;
    CCSprite *introCommit;

    
    BOOL movingLayer;
    
    NSMutableArray *dotMatrix;
    NSDictionary *hiddenRows;
    NSMutableArray *numberWheels;
    
    NSMutableArray *reqShapesCopy;
    
    DWNWheelGameObject *sumWheel;
    
    NSMutableArray *visibleAnchors;
    NSMutableArray *invisibleAnchors;
    CGRect drawnArea;
    
    CCDrawNode *drawNode;
    
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    
    int spaceBetweenAnchors;
    int startX;
    int startY;
    
    CGPoint pickupAnchorPoint;
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)populateGW;
-(void)checkAnchors;
-(void)checkAnchorsAndUseResizeHandle:(BOOL)showResize andShowMove:(BOOL)showMove andPrecount:(NSArray*)preCountedTiles andDisabled:(BOOL)Disabled;
-(void)checkAnchorsOfExistingShape:(DWDotGridShapeGameObject*)thisShape;
-(void)checkAnchorsOfExistingShapeGroup:(DWDotGridShapeGroupGameObject*)thisShapeGroup;
-(DWDotGridShapeGameObject*)createShapeWithAnchorPoints:(NSArray*)anchors andPrecount:(NSArray*)preCountedTiles andDisabled:(BOOL)Disabled;
-(DWDotGridShapeGameObject*)createShapeWithAnchorPoints:(NSArray*)anchors andPrecount:(NSArray*)preCountedTiles andDisabled:(BOOL)Disabled andGroup:(DWGameObject*)shapeGroup;
-(void)modifyThisShape:(DWDotGridShapeGameObject*)thisShape withTheseAnchors:(NSArray*)anchors;
-(void)removeDeadWheel:(DWNWheelGameObject*)thisWheel;
-(void)updateSumWheel;
-(void)createSumWheel;
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
