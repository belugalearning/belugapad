//
//  PieSplitter.h
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "ToolConsts.h"
#import "ToolScene.h"
@class DWPieSplitterPieGameObject;
@class DWPieSplitterContainerGameObject;

typedef enum {
    kGameCannotSplit=0,
    kGameReadyToSplit=1,
    kGameSlicesActive=2
    
} GameState;

typedef enum {
    kLabelShowFraction=0,
    kLabelShowDecimal=1
} LabelType;

@interface PieSplitter : ToolScene
{
    // required toolhost stuff
    ToolHost *toolHost;
    
    //gameworld
    DWGameWorld *gw;
    GameState gameState;
    
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
    float timeSinceInteractionOrShake;
    
    // and a default layer
    CCLayer *renderLayer;
    CCLayer *movementLayer;
    
    // pdef options
    BOOL showReset;
    BOOL startProblemSplit;
    BOOL reqCorrectPieSquaresToSplit;
    BOOL madeGhost;
    int numberOfCagedPies;
    int numberOfCagedContainers;
    int numberOfActivePies;
    int numberOfActiveContainers;
    int numberOfCagedSlices;
    int dividend;
    int divisor;
    
    // this is for tinting on an equal amount in every pie
    BOOL sparkles;
    
    int slicesInEachPie;
    
    float lastLayerOffset;
    
    // then our specifics
    DWPieSplitterContainerGameObject *newCon;
    DWPieSplitterPieGameObject *newPie;
    
    BOOL createdNewCon;
    BOOL createdNewPie;
    BOOL hasSplit;
    BOOL showResetSlicesToPies;
    BOOL hasASliceInCont;
    BOOL showNewPieCont;
    BOOL moveInitObjects;
    
    CCSprite *pieBox;
    CCSprite *conBox;
    CCSprite *resetSlices;
    
    DWGameObject *ghost;
    
    NSMutableArray *activePie;
    NSMutableArray *activeCon;
    NSMutableArray *activeLabels;
    
    BOOL hasMovedSlice;
    BOOL hasMovedPie;
    BOOL hasMovedSquare;
    
    int createdPies;
    int createdCont;
    
    LabelType labelType;
    
    
}

-(void)readPlist:(NSDictionary*)pdef;
-(void)populateGW;
-(void)createPieAtMount;
-(void)createContainerAtMount;
-(void)addGhostPie;
-(void)addGhostContainer;
-(void)removeGhost;
-(void)reorderActivePies;
-(void)reorderActiveContainers;
-(void)splitPie:(DWPieSplitterPieGameObject*)p;
-(void)splitPies;
-(void)removeSlices;
-(void)balanceLayer;
-(void)balanceContainers;
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
