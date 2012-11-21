//
//  ToolTemplateSG.h
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "ToolConsts.h"
#import "ToolScene.h"
#import "SGBtxeProtocols.h"

@class SGBtxeRow;

@interface ExprBuilder : ToolScene
{
    // required toolhost stuff
    ToolHost *toolHost;
    
    // standard Problem Definition stuff
    ProblemEvalMode evalMode;
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    
    // default positional bits
    CGPoint winL;
    float cx, cy, lx, ly;
    
    // common touch interactions
    BOOL isTouching;
    CGPoint lastTouch;
    
    // standard to move between problems
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    
    // and a default layer
    CCLayer *renderLayer;
    
    BOOL isHoldingObject;
    id<MovingInteractive> heldObject;
    CGPoint heldOffset;
    
    //expressions
    NSArray *exprStages;
    
    NSString *evalType;
    
    NSMutableArray *rows;

    int repeatRow2Count;
    int userRepeatRow2Max;
    
    //is increased to 1 if the pdef decsription gets inserted
    int rowIndexOffset;
    
    BOOL presentNumberCardRow;
    int numberCardRowMin;
    int numberCardRowMax;
    int numberCardRowInterval;
    BOOL numberCardRandomOrder;
    int numberCardRandomSelectionOf;
    
    SGBtxeRow *ncardRow;
    
    //excluded row evaluations
    NSArray *excludedEvalRows;
    
    //expression build
    NSMutableArray *tokens;
    NSDictionary *curToken;
    int curTokenIdx;
    
    NSMutableArray *expressionStringCache;
    
}

-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef;
-(void)populateGW;
-(void)readPlist:(NSDictionary*)pdef;
-(void)doUpdate:(ccTime)delta;
-(void)draw;
-(BOOL)evalExpression;
-(void)evalProblem;
-(void)resetProblem;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)dealloc;

@end
