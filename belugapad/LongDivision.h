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
    NSArray *solutionsDef;
    
    DWNWheelGameObject *nWheel;
    
    CGPoint lastTouch;
    CGPoint touchStart;
    
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    ProblemEvalMode evalMode;
    
    
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    
    BOOL topTouch;
    BOOL bottomTouch;
    BOOL startedInActiveRow;
    BOOL doingHorizontalDrag;
    BOOL doingVerticalDrag;
    
    BOOL goodBadHighlight;
    BOOL renderBlockLabels;
    BOOL movedTopSection;
    BOOL hideRenderLayer;
    
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
    float rowMultiplier;
    int startColValue;
    
    int currentTouchCount;
    
    NSMutableArray *selectedNumbers;
    NSMutableArray *rowMultipliers;
    NSMutableArray *drawnObjects;
    
    // rendering vars
    float cumulativeTotal;
    float lastBaseEval;
    float currentScaleY;
    NSMutableArray *renderedBlocks;
    NSMutableDictionary *labelInfo;
    
    
    //problem state
    BOOL expressionIsEqual;
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)createVisibleNumbers;
-(void)updateLabels:(CGPoint)position;
-(void)updateBlock;
-(void)checkBlockWithBase:(float)thisBase andSelection:(int)thisSelection;
-(void)createBlockAtIndex:(int)index withBase:(float)base;
-(void)populateGW;
-(void)handlePassThruScaling:(float)scale;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(BOOL)evalExpression;
-(void)evalProblem;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;

@end