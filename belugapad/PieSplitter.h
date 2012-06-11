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
    
    // pdef options
    BOOL showReset;
    BOOL startProblemSplit;
    int numberOfCagedPies;
    int numberOfCagedContainers;
    int numberOfActivePies;
    int numberOfActiveContainers;
    int dividend;
    int divisor;
    
    // then our specifics
    DWPieSplitterContainerGameObject *newCon;
    DWPieSplitterPieGameObject *newPie;
    BOOL createdNewCon;
    BOOL createdNewPie;
    BOOL hasSplit;
    
    CCSprite *pieBox;
    CCSprite *conBox;
    
    DWGameObject *ghost;
    
    NSMutableArray *activePie;
    NSMutableArray *activeCon;
    
    int createdPies;
    int createdCont;
    
    
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
