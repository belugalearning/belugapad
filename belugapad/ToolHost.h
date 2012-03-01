//
//  ToolHost.h
//  belugapad
//
//  Created by Gareth Jenkins on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

typedef enum {
    kMetaQuestionAnswerSingle=0,
    kMetaQuestionAnswerMulti=1
} MetaQuestionAnswerMode;
typedef enum {
    kMetaQuestionEvalAuto=0,
    kMetaQuestionEvalOnCommit=1
} MetaQuestionEvalMode;

@class Daemon;
@class ToolScene;

@interface ToolHost : CCLayer
{
    float cx, cy, lx, ly;
    
    NSArray *problemList;
    int problemIndex;
    
    CCLayer *perstLayer;
    CCLayer *backgroundLayer;
    CCLayer *metaQuestionLayer;

    CCLayer *toolBackLayer;
    CCLayer *toolForeLayer;
    
    ToolScene *currentTool;
    
    MetaQuestionEvalMode mqEvalMode;
    MetaQuestionAnswerMode mqAnswerMode;
    
    BOOL metaQuestionForThisProblem;
    NSMutableArray *metaQuestionAnswers;
    NSMutableArray *metaQuestionAnswerButtons;
    NSMutableArray *metaQuestionAnswerLabels;
    int metaQuestionAnswerCount;
    NSString *metaQuestionCompleteText;
    NSString *metaQuestionIncompleteText;
    CCLabelTTF *metaQuestionIncompleteLabel;
    BOOL showMetaQuestionIncomplete;
    float shownMetaQuestionIncompleteFor;
    
    NSDictionary *pdef;
}

@property (retain) Daemon *Zubi;

+(CCScene *) scene;

-(NSDictionary*)getNextProblem;
-(void)loadTestPipeline;
-(void) loadTool;
-(void) addToolForeLayer:(CCLayer *) foreLayer;
-(void) addToolBackLayer:(CCLayer *) backLayer;
-(void) populatePerstLayer;
-(void) gotoNewProblem;
-(void) loadProblem;
-(void) resetProblem;
-(void)doUpdateOnTick:(ccTime)delta;
-(void)doUpdateOnSecond:(ccTime)delta;
-(void)doUpdateOnQuarterSecond:(ccTime)delta;

-(void)recurseSetIntroFor:(CCNode*)node withTime:(float)time forTag:(int)tag;
-(void)stageIntroActions;

-(void)setupMetaQuestion:(NSDictionary *)pdefMQ;
-(void)checkMetaQuestionTouches:(CGPoint)location;
-(void)evalMetaQuestion;
-(void)deselectAnswersExcept:(int)answerNumber;
-(void)doWinning;
-(void)doIncomplete;
-(void)removeMetaQuestionButtons;
-(void)tearDownMetaQuestion;

@end
