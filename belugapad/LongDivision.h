//
//  LongDivision.h
//  belugapad
//
//  Created by David Amphlett on 25/04/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "ToolConsts.h"
#import "ToolScene.h"
#import "DWNWheelGameObject.h"

@interface LongDivision : ToolScene
{
    ToolHost *toolHost;
    DWGameWorld *gw;
    
    CCLayer *topSection;
    CCLayer *bottomSection;
    
    CGPoint winL;
    float cx, cy, lx, ly;
    
    BOOL isTouching;
    
    CCLayer *renderLayer;
    
    CCLabelTTF *lblCurrentTotal;
    CCSprite *line;
    CCSprite *marker;
    CCLabelTTF *markerText;
    CCSprite *startMarker;
    CCSprite *endMarker;
    
    NSMutableArray *numberRows;
    NSMutableArray *numberLayers;
    NSMutableArray *allLabels;
    NSMutableArray *allSprites;
    NSArray *solutionsDef;
    
    DWNWheelGameObject *nWheel;

    
    CGPoint lastTouch;
    CGPoint touchStart;
    
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    ProblemEvalMode evalMode;
    
    
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    
    BOOL goodBadHighlight;
    BOOL renderBlockLabels;
    
    
    BOOL audioHasPlayedOverTarget;
    BOOL audioHasPlayedOnTarget;
    
    BOOL hasEvaluated;
    
    float dividend;
    float divisor;
    float highestBase;
    
    int columnsInPicker;
    int currentRowPos;
    int activeRow;
    int previousRow;
    int currentNumberPos;
    int previousNumberPos;
    float currentTotal;
    float lastTotal;
    float rowMultiplier;
    int startColValue;
    
    BOOL renderingChanges;
    
    NSMutableArray *drawnObjects;
    
    // rendering vars
    float cumulativeTotal;
    float lastBaseEval;
    float currentScaleY;
    NSMutableArray *renderedBlocks;
    NSMutableDictionary *labelInfo;
    
    
    //problem state
    BOOL expressionIsEqual;
    
    CCDrawNode *drawNode;
    CCDrawNode *scaleDrawNode;
    CCClippingNode *clippingNode;
    
    CCSprite *magnifyBar;
    CCSprite *maskOuter;
    CCSprite *spriteMask;
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)populateGW;
-(void)evalProblem;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;

@end