//
//  LDivision.h
//  belugapad
//
//  Created by David Amphlett on 25/04/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "ToolConsts.h"
#import "ToolScene.h"
#import "DWNWheelGameObject.h"

@interface LDivision : ToolScene
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
    float rowMultiplier;
    int startColValue;
    
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
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)updateLabels:(CGPoint)position;
-(void)populateGW;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(BOOL)evalExpression;
-(void)evalProblem;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;

@end