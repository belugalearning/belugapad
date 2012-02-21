//
//  BlockFloating.h
//  belugapad
//
//  Created by Gareth Jenkins on 27/12/2011.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"
#import "chipmunk.h"
#import "DWGameWorld.h"
#import "DWGameObject.h"
#import "ToolConsts.h"
#import "ToolScene.h"

@class Daemon;

@interface BlockFloating : ToolScene
{
    ToolHost *toolHost;
    NSDictionary *problemDef;
    
    float cx;
    float cy;
    
    DWGameWorld *gameWorld;
    
    BOOL touching;
    
    cpSpace *space;
    
    CCLabelTTF *problemDescLabel;
    CCLabelTTF *problemSubLabel;
    NSArray *solutionsDef;
    CCLabelTTF *problemCompleteLabel;
    
    NSArray *problemFiles;
    int currentProblemIndex;
    
    NSArray *tutorials;
    BOOL doTutorials;
    int tutorialPos;
    int tutorialLastParsed;
    CCLayer *ghostLayer;
    float timeToNextTutorial;
    
    BOOL problemIsCurrentlySolved;
    
    BOOL daemonIsGhosting;
    
    //pulled direct from problem def -- both default to 0 state if not defined
    ProblemRejectMode rejectMode;
    ProblemEvalMode evalMode;
    
    //the last positively evaluated clauses's solution index
    int trackedSolutionIndex;
    BOOL trackingSolution;
    
    //timer to next problem
    BOOL autoMoveToNextProblem;
    float timeToAutoMoveToNextProblem;

    DWGameObject *opGOtarget;
    DWGameObject *opGOsource;
    
    BOOL enableOperators;
    CCLayer *operatorLayer;
    CCSprite *operatorPanel;
}

-(void) setupBkgAndTitle;
-(void) setupAudio;
-(void) setupSprites;
-(void) setupGW;
-(void) populateGW:(NSDictionary *)pdef;
-(void) setupChSpace;
-(void) doUpdate:(ccTime)delta;
-(void) attachBodyToGO:(DWGameObject *)attachGO atPositionPayload:(NSDictionary *)positionPayload;

-(void)spawnObjects:(NSDictionary*)objects;

-(void)createObjectWithCols:(int)cols andRows:(int)rows andUnitCount:(int)unitcount andTag:(NSString*)tagString;
-(void)createContainerWithPos:(CGPoint)pos andData:(NSDictionary*)containerData;

// both abstracted (i.e. from gw implementation) but fixed to this tool's current problem load -- hence effectively a single-problem evaluation prototype of abstracted (from gw) evaluation
-(void)evalCompletionWithForceCommit:(BOOL)forceCommit;
-(void)evalCompletionOnTimer:(ccTime)delta;
-(void)evalCommit;
-(void)doProblemSolvedActionsFor:(NSDictionary*)sol withCompletion:(int)solComplete andScore:(float)solScore;

-(void)doClauseActionsWithForceNow:(BOOL)forceRejectNow;

-(float)getEvaluatedValueForItemTag: (NSString *)itemContainerTag andItemValue:(NSNumber*)itemValue andValueRequiredIsSize:(BOOL)valIsSize;

-(int)evalClauses:(NSDictionary*)clauses withSolIndex:(int)solIndex;

-(void)clearGhost;
-(void)showGhostOf:(NSString *)ghostObjectTag to:(NSString *)ghostDestinationTag;
-(CCNode *)ghostCopySprite:(CCSprite*)spriteSource;
-(void)updateTutorials:(ccTime)delta;
-(void)parseTutorialActionsFor:(NSDictionary*)actionSet;
-(void)considerProximateObjects:(ccTime)delta;
-(void)showOperators;
-(void)disableOperators;
-(void)setOperators;
-(void)doAddOperation;
-(void)doSubtractOperation;

-(void)doUpdate:(ccTime)delta;

@end
