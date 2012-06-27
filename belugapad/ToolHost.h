//
//  ToolHost.h
//  belugapad
//
//  Created by Gareth Jenkins on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "ToolConsts.h"

typedef enum {
    kMetaQuestionAnswerSingle=0,
    kMetaQuestionAnswerMulti=1
} MetaQuestionAnswerMode;
typedef enum {
    kMetaQuestionEvalAuto=0,
    kMetaQuestionEvalOnCommit=1
} MetaQuestionEvalMode;
typedef enum {
    kNumberPickerCalc=0,
    kNumberPickerSingleLine=1,
    kNumberPickerDoubleLineHoriz=2,
    kNumberPickerDoubleColumnVert=3
}NumberPickerType;
typedef enum {
    kNumberPickerEvalAuto=0,
    kNumberPickerEvalOnCommit=1
}NumberPickerEvalMode;

@class Daemon;
@class ToolScene;
@class BAExpressionTree;
@class UsersService;
@class DProblemParser;
@class NordicAnimator;
@class LRAnimator;

@interface ToolHost : CCLayer
{
    float cx, cy, lx, ly;
    
    CCLayer *perstLayer;
    CCLayer *backgroundLayer;
    CCLayer *metaQuestionLayer;
    CCLayer *numberPickerLayer;
    CCLayer *problemDefLayer;
    CCLayer *pauseLayer;

    CCLayer *toolBackLayer;
    CCLayer *toolForeLayer;
    CCLayer *toolNoScaleLayer;
    
    CCNode *nPicker;
    
    CGPoint lastTouch;
    
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
    BOOL metaQuestionForceComplete;
    
    BOOL numberPickerForThisProblem;
    BOOL animatePickedButtons;
    NumberPickerType numberPickerType;
    NumberPickerEvalMode numberPickerEvalMode;
    NSMutableArray *numberPickerButtons;
    NSMutableArray *numberPickedSelection;
    NSMutableArray *numberPickedValue;
    CCSprite *npMove;
    CCSprite *npLastMoved;
    CGPoint npMoveStartPos;
    CCSprite *npDropbox;
    float npEval;
    int npMaxNoInDropbox;
    CGRect pickerBox;
    BOOL hasMovedNumber;
    BOOL hasUsedNumber;
    
    float timeSinceInteractionOrShakeNP;
    
    BOOL isPaused;
    CCLabelTTF *pauseTestPathLabel;
    
    BOOL showingProblemComplete;
    BOOL showingProblemIncomplete;
    float shownProblemStatusFor;
    
    NSMutableDictionary *pdef;
    
    BOOL skipNextStagedIntroAnim;
    
    CCSprite *hostBackground;
    CCSprite *pauseMenu;
    CCSprite *problemComplete;
    CCSprite *problemIncomplete;
    
    BOOL autoMoveToNextProblem;
    float moveToNextProblemTime;
    
    float scale;
    
    CCLabelTTF *problemDescLabel;
    ProblemEvalMode evalMode;
    
    CCSprite *commitBtn;
    
    LRAnimator *animator;
    int animPos;
    
    int currentToolDepth;
    
    NSString *touchLogPath;
    
    BOOL isGlossaryMock;
    BOOL isGloassryDone1;
    BOOL glossaryShowing;
    CCSprite *glossary1;
    CCSprite *glossary2;
    CCSprite *glossaryPopup;
}

@property (retain) Daemon *Zubi;
@property (retain) BAExpressionTree *PpExpr;
@property BOOL flagResetProblem;
@property (retain) DProblemParser *DynProblemParser;

+(CCScene *) scene;

-(void) loadTool;
-(void) addToolNoScaleLayer:(CCLayer *) noScaleLayer;
-(void) addToolForeLayer:(CCLayer *) foreLayer;
-(void) addToolBackLayer:(CCLayer *) backLayer;
-(void) populatePerstLayer;
-(void) gotoNewProblem;
-(void) loadProblem;
-(void) resetProblem;
-(void) showPauseMenu;
-(void) checkPauseTouches:(CGPoint)location;
-(void) returnToMenu;
-(void) showProblemCompleteMessage;
-(void) showProblemIncompleteMessage;
-(void)doUpdateOnTick:(ccTime)delta;
-(void)doUpdateOnSecond:(ccTime)delta;
-(void)doUpdateOnQuarterSecond:(ccTime)delta;
-(void)recurseSetIntroFor:(CCNode*)node withTime:(float)time forTag:(int)tag;
-(void)stageIntroActions;
-(void)setupProblemOnToolHost:(NSDictionary *)pdef;
-(void)setupMetaQuestion:(NSDictionary *)pdefMQ;
-(void)checkMetaQuestionTouches:(CGPoint)location;
-(void)setupNumberPicker:(NSDictionary *)pdefNP;
-(void)checkNumberPickerTouches:(CGPoint)location;
-(void)checkNumberPickerTouchOnRegister:(CGPoint)location;
-(void)evalNumberPicker;
-(void)reorderNumberPickerSelections;
-(void)evalMetaQuestion;
-(void)deselectAnswersExcept:(int)answerNumber;
-(void)doWinning;
-(void)doIncomplete;
-(void)removeMetaQuestionButtons;
-(void)tearDownNumberPicker;
-(void)tearDownMetaQuestion;
-(void)tearDownProblemDef;
-(void)readToolOptions:(NSString*)currentTool;


-(void) moveToTool1: (ccTime) delta;
-(void) gotoFirstProblem: (ccTime) delta;

-(void)playAudioClick;
-(void)playAudioPress;

@end
