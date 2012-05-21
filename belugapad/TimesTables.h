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



@interface TimesTables : ToolScene
{
    ToolHost *toolHost;
    DWGameWorld *gw;
    
    ProblemEvalMode evalMode;
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    
    OperatorMode operatorMode;
    NSString *operatorName;

    
    CGPoint winL;
    float cx, cy, lx, ly;
    
    BOOL isTouching;
    
    CCLayer *renderLayer;
    
    NSArray *solutionsDef;
    
    CGPoint lastTouch;

    
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    
    int spaceBetweenAnchors;
    int startX;
    int startY;
    BOOL showXAxis;
    BOOL showYAxis;
    NSMutableArray *ttMatrix;
    NSMutableArray *activeCols;
    NSMutableArray *activeRows;
    NSMutableArray *headerLabels;
    NSMutableArray *bubbles;
    CCSprite *selection;
    int currentXHighlightNo;
    int currentYHighlightNo;
    BOOL currentXHighlight;
    BOOL currentYHighlight;
    BOOL allowHighlightX;
    BOOL allowHighlightY;
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)populateGW;
-(void)tintRow:(int)thisRow;
-(void)tintCol:(int)thisCol;
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
