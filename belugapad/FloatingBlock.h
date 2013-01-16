//
//  FractionBuilder.h
//  belugapad
//
//  Created by Gareth Jenkins on 23/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "ToolConsts.h"
#import "ToolScene.h"
#import "CCPickerView.h"

typedef enum {
    kSolutionMatch=0,
    kSolutionEquivalents=1,
    kSolutionAddition=2
} SolutionType;

@interface FloatingBlock : ToolScene <CCPickerViewDataSource, CCPickerViewDelegate>
{
    // required toolhost stuff
    ToolHost *toolHost;
    
    // standard Problem Definition stuff
    ProblemEvalMode evalMode;
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    SolutionType solutionType;
    
    // default positional bits
    CGPoint winL;
    CGPoint touchStartPos;
    float cx, cy, lx, ly;
    
    // common touch interactions
    BOOL isTouching;
    CGPoint lastTouch;
    
    // standard to move between problems
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    
    // showing stuff?
    BOOL showingOperatorBubble;
    BOOL setupNumberWheel;
    BOOL hasLoggedMove;
    BOOL isInBubble;
    BOOL isIntroPlist;
    float timeToSetupNumberWheel;
    
    // and a default layer
    CCLayer *renderLayer;
    
    CCSprite *commitPipe;
    CCSprite *newPipe;
    CCLabelTTF *commitLabel;
    BOOL showNewPipe;
    
    NSMutableArray *pickerViewSelection;
    
    // init stuff
    int initBubbles;
    NSArray *supportedOperators;
    NSArray *initObjects;
    BOOL bubbleAutoOperate;
    BOOL showMultipleControls;
    BOOL showSolutionOnPipe;
    int maxBlocksInGroup;
    int minBlocksFromPipe;
    int maxBlocksFromPipe;
    int defaultBlocksFromPipe;
    
    int blocksFromPipe;
    
    
    int expSolution;
    
    
    BOOL audioHasPlayedBubbleProx;
}

@property (nonatomic, retain) CCPickerView *pickerView;

-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef;
-(void)doUpdateOnTick:(ccTime)delta;
-(void)draw;
-(void)readPlist:(NSDictionary*)pdef;
-(void)populateGW;
-(void)createShapeWith:(NSDictionary*)theseSettings;
-(void)createShapeWith:(NSDictionary*)theseSettings andObj:(int)thisObj of:(int)thisMany;
-(void)handleMergeShapes;
-(void)showOperatorBubbleOrMerge;
-(void)mergeGroupsFromBubbles;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
-(BOOL)evalExpression;
-(void)evalProblem;
-(void)resetProblem;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;

-(void)dealloc;

@end
