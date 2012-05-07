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
    
    NSMutableArray *numberRows;
    NSMutableArray *numberLayers;
    NSArray *solutionsDef;
    
    CGPoint lastTouch;
    CGPoint touchStart;
    
    ProblemRejectMode rejectMode;
    ProblemEvalMode evalMode;
    
    
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    
    BOOL topTouch;
    BOOL bottomTouch;
    BOOL startedInActiveRow;
    BOOL doingHorizontalDrag;
    BOOL doingVerticalDrag;
    
    BOOL goodBadHighlight;
    
    float dividend;
    float divisor;
    
    int currentRowPos;
    int activeRow;
    int previousRow;
    int currentNumberPos;
    int previousNumberPos;
    float currentTotal;
    float rowMultiplier;
    float startRow;
    
    int currentTouchCount;
    
    NSMutableArray *selectedNumbers;
    NSMutableArray *rowMultipliers;
    NSMutableArray *drawnObjects;
    
    // rendering vars
    float cumulativeTotal;
    float lastBaseEval;
    float currentScaleY;
    BOOL creatingObject;
    BOOL destroyingObject;
    NSMutableArray *renderedBlocks;
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)createVisibleNumbers;
-(void)updateLabels:(CGPoint)position;
-(void)updateBlock;
-(void)checkBlock;
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