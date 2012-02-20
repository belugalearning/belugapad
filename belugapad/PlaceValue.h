//
//  PlaceValue.h
//  belugapad
//
//  Created by David Amphlett on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "cocos2d.h"
#import "ToolConsts.h"
@class DWGameWorld;
@class Daemon;
@interface PlaceValue : CCLayer
{
    BOOL touching;
    BOOL potentialTap;
    
    CGPoint winL;
    float cx, cy, lx, ly;
    
    CCLayer *renderLayer;
    
    CCLabelTTF *problemDescLabel;
    CCLabelTTF *problemSubLabel;
    CCLabelTTF *problemCompleteLabel;
    CCLabelTTF *countLabel;
    CCLabelTTF *countLabelBlock;

    // GameWorld setup

    int ropesforColumn;
    int rows;    
    float currentColumnIndex;
    float defaultColumn;
    float columnBaseValue;
    float firstColumnValue;
    float totalObjectValue;
    int numberOfColumns;    
    
    // GameWorld options
    
    BOOL showCage;
    BOOL showCount;
    BOOL showValue;
    BOOL showBaseSelection;
    BOOL showCountOnBlock;
    BOOL showColumnHeader;
    
    NSMutableArray *columnInfo;
    
    NSArray *problemFiles;
    int currentProblemIndex;
    
    NSDictionary *solutionsDef;
    NSDictionary *columnSprites;
    
    DWGameWorld *gw;
    Daemon *daemon;

    CGPoint touchStartPos;
    CGPoint touchEndPos;
    
    NSArray *initObjects;
    
    ProblemRejectMode rejectMode;
    ProblemEvalMode evalMode;
    
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    BOOL autoHideStatusLabel;
    float timeToHideStatusLabel;
    
    int lastCount;
    
    CCSprite *condensePanel;
    CCSprite *mulchPanel;
    
    BOOL inBlockTransition;
    BOOL inCondenseArea;
    BOOL inMulchArea;
}

+(CCScene *)scene;
-(void)doUpdate:(ccTime)delta;
-(void)populateGW;
-(void)setupProblem;
-(void)setupBkgAndTitle;
-(void)listProblemFiles;
-(void)resetToNextProblem;
-(void)readPlist;
-(void)problemStateChanged;
-(void)evalProblem;
-(void)doWinning;
-(void)evalProblemCountSeq;
-(void)evalProblemTotalCount;
-(void)evalProblemMatrixMatch;
-(void)snapLayerToPosition;

-(void)doCondenseFromLocation:(CGPoint)location;
-(void)doMulchFromLocation:(CGPoint)location;
-(void)doTransitionWithIncrement:(int)incr;

@end