//
//  ToolHost.h
//  belugapad
//
//  Created by Gareth Jenkins on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "ToolConsts.h"
#import "CCPickerView.h"

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
@class SGGameWorld;
@class DebugViewController;
@class EditPDefViewController;
@class SGBtxeRow;

@interface ToolHost : CCLayer <CCPickerViewDataSource, CCPickerViewDelegate>
{
    float cx, cy, lx, ly;
    
    CCLayer *perstLayer;
    CCLayer *backgroundLayer;
    CCLayer *metaQuestionLayer;
    CCLayer *numberPickerLayer;
    CCLayer *problemDefLayer;
    CCLayer *btxeDescLayer;
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
    CCSprite *metaQuestionBanner;
    BOOL showMetaQuestionIncomplete;
    float shownMetaQuestionIncompleteFor;
    BOOL metaQuestionForceComplete;
    BOOL metaQuestionRandomizeAnswers;
    
    BOOL numberPickerForThisProblem;
    BOOL animatePickedButtons;
    NumberPickerType numberPickerType;
    NumberPickerEvalMode numberPickerEvalMode;
    NSMutableArray *numberPickerButtons;
    NSMutableArray *numberPickedSelection;
    NSMutableArray *numberPickedValue;
    NSMutableArray *pickerViewSelection;
    CCSprite *npMove;
    CCSprite *npLastMoved;
    CGPoint npMoveStartPos;
    CCSprite *npDropbox;
    float npEval;
    int npMaxNoInDropbox;
    CGRect pickerBox;
    BOOL hasMovedNumber;
    BOOL hasUsedNumber;
    BOOL canMoveNumber;
    
    float timeSinceInteractionOrShake;
    float timeBeforeUserInteraction;
    
    BOOL isPaused;
    CCLabelTTF *pauseTestPathLabel;
    
    BOOL showingProblemComplete;
    BOOL showingProblemIncomplete;
    float shownProblemStatusFor;
    
    NSMutableDictionary *pdef;
    
    BOOL skipNextStagedIntroAnim;
    BOOL skipNextDescDraw;
    
    CCSprite *hostBackground;
    CCSprite *pauseMenu;
    CCSprite *problemComplete;
    CCSprite *problemIncomplete;
    CCSprite *pbtn;
    
    BOOL autoMoveToNextProblem;
    float moveToNextProblemTime;
    
    float scale;
    
    CCLabelTTF *problemDescLabel;
    ProblemEvalMode evalMode;
    
    
    CCSprite *readProblemDesc;
    CCSprite *commitBtn;
    CCSprite *metaArrow;
    
    LRAnimator *animator;
    int animPos;
    
    int currentToolDepth;
    
    NSString *touchLogPath;
    
    BOOL isGlossaryMock;
    BOOL isGloassryDone1;
    BOOL glossaryShowing;
    BOOL isAnimatingIn;
    CCSprite *glossary1;
    CCSprite *glossary2;
    CCSprite *glossaryPopup;
    
    
    //scoring
    int pipelineScore;          //the total score accumulated in this pipeline
    int displayScore;           //the score currently being displayed (not actual -- based on sharding)
    int displayPerShard;        //the displayed score accumulation per shard
    float scoreMultiplier;      //the current multiplier
    int multiplierStage;        //the stage of the multiplier (0 for first problem)
    BOOL hasResetMultiplier;    //has the multiplier been reset this problem (e.g. problem failed & restarted)
    
    CCLabelTTF *scoreLabel;
    CCLabelTTF *multiplierLabel;
    
    //adpline trgigers
    BOOL adpSkipProblemAndInsert;
    int commitCount;
    NSDictionary *triggerData;
    
    //web debug view
    UIWebView *debugWebView;
    BOOL debugShowingPipelineState;
    DebugViewController *debugViewController;
    
    //btxe for description
    SGGameWorld *descGw;
    CCSprite *questionSeparatorSprite;
    SGBtxeRow *descRow;
    
    //ui
    CCSprite *multiplierBadge;
    CCLayerColor *blackOverlay;
    CCLayer *contextProgressLayer;
    
    //tooltrays
    CCSprite *traybtnWheel;
    CCSprite *traybtnMq;
    CCSprite *traybtnCalc;
    CCSprite *traybtnPad;
    
    BOOL trayWheelShowing;
    BOOL trayMqShowing;
    BOOL trayCalcShowing;
    BOOL trayPadShowing;
    
    BOOL trayCornerShowing;
    
    CCLayer *trayLayerCalc;
    CCLayer *trayLayerWheel;
    CCLayer *trayLayerMq;
    CCLayer *trayLayerPad;
    
    BOOL hasTrayWheel;
    BOOL hasTrayCalc;
    BOOL hasTrayMq;
    BOOL showMqOnStart;
    
    BOOL hasUsedPicker;
    BOOL hasUsedWheelTray;
    BOOL hasUsedMetaTray;
    
    BOOL delayShowWheel;
    BOOL delayShowMeta;
    float timeToWheelStart;
    float timeToMetaStart;
    
    BOOL evalShowCommit;
    
}

@property (retain) Daemon *Zubi;
@property (retain) BAExpressionTree *PpExpr;
@property BOOL flagResetProblem;
@property BOOL toolCanEval;
@property (retain) DProblemParser *DynProblemParser;
@property (nonatomic, retain) CCPickerView *pickerView;
@property (retain) id CurrentBTXE;

+(CCScene *) scene;

-(void) loadTool;
-(void) addToolNoScaleLayer:(CCLayer *) noScaleLayer;
-(void) addToolForeLayer:(CCLayer *) foreLayer;
-(void) addToolBackLayer:(CCLayer *) backLayer;
-(void) populatePerstLayer;
-(void) shakeCommitButton;
-(void) gotoNewProblem;
-(void) loadProblem;
-(void) resetProblem;
-(void) showPauseMenu;
-(void) checkPauseTouches:(CGPoint)location;
-(void) showProblemCompleteMessage;
-(void) showProblemIncompleteMessage;
-(void)showHideCommit;
-(void)showWheel;
-(void)hideWheel;
-(void)doUpdateOnTick:(ccTime)delta;
-(void)doUpdateOnSecond:(ccTime)delta;
-(void)doUpdateOnQuarterSecond:(ccTime)delta;
-(void)recurseSetIntroFor:(CCNode*)node withTime:(float)time forTag:(int)tag;
-(void)stageIntroActions;
-(void)setupProblemOnToolHost:(NSDictionary *)pdef;
-(NSMutableArray*)randomizeAnswers:(NSMutableArray*)thisArray;
-(void)setupMetaQuestion:(NSDictionary *)pdefMQ;
-(void)checkMetaQuestionTouchesAt:(CGPoint)location andTouchEnd:(BOOL)touchEnd;
-(void)setupNumberPicker:(NSDictionary *)pdefNP;
-(void)checkNumberPickerTouches:(CGPoint)location;
-(void)checkNumberPickerTouchOnRegister:(CGPoint)location;
-(void)evalNumberPicker;
-(void)reorderNumberPickerSelections;
-(BOOL)calcMetaQuestion;
-(void)evalMetaQuestion;
-(void)deselectAnswersExcept:(int)answerNumber;
-(void)doWinning;
-(void)doIncomplete;
-(void)removeMetaQuestionButtons;
-(void)tearDownNumberPicker;
-(void)tearDownMetaQuestion;
-(void)tearDownProblemDef;
-(void)readToolOptions:(NSString*)currentTool;
-(void)incrementDisplayScore: (id)sender;
-(NSString*)returnPickerNumber;
-(void)updatePickerNumber:(NSString*)thisNumber;


-(void) moveToTool1: (ccTime) delta;
-(void) gotoFirstProblem: (ccTime) delta;

-(void)playAudioClick;
-(void)playAudioPress;

-(void)resetScoreMultiplier;

@end
