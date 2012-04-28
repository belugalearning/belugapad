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
    
    float dividend;
    float divisor;
    
    int currentRowPos;
    int activeRow;
    int currentNumberPos;
    float rowMultiplier;
    float startRow;
    
    NSMutableArray *selectedNumbers;
    NSMutableArray *rowMultipliers;
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)createVisibleNumbers;
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