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

@class Daemon;

typedef enum {
    kRejectNever=0,
    kRejectOnCommit=1,
    kRejectOnAction=2
} RejectMode;

typedef enum {
    kEvalAuto=0,
    kEvalOnCommit=1
} EvalMode;

@interface BlockFloating : CCLayer
{
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
    
    Daemon *daemon;
    BOOL daemonIsGhosting;
    
    //pulled direct from problem def -- both default to 0 state if not defined
    RejectMode rejectMode;
    EvalMode evalMode;
    
    //the last positively evaluated clauses's solution index
    int trackedSolutionIndex;
    BOOL trackingSolution;
    
    //timer to next problem
    BOOL autoMoveToNextProblem;
    float timeToAutoMoveToNextProblem;

}

+(CCScene *) scene;

-(void) setupBkgAndTitle;
-(void) setupAudio;
-(void) setupSprites;
-(void) setupGW;
-(void) populateGW;
-(void)setupChSpace;
-(void) doUpdate:(ccTime)delta;
-(void) attachBodyToGO:(DWGameObject *)attachGO atPositionPayload:(NSDictionary *)positionPayload;

-(void)spawnObjects:(NSDictionary*)objects;

-(void)createObjectWithCols:(int)cols andRows:(int)rows andTag:(NSString*)tag;
-(void)createContainerWithPos:(CGPoint)pos andData:(NSDictionary*)containerData;

-(void)listProblemFiles;
-(void) resetToNextProblem;

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
-(CCSprite *)ghostCopySprite:(CCSprite*)spriteSource;
-(void)updateTutorials:(ccTime)delta;
-(void)parseTutorialActionsFor:(NSDictionary*)actionSet;

@end
