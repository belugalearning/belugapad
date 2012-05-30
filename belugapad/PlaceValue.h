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
#import "ToolScene.h"

@class DWGameWorld;
@class Daemon;
@class ToolHost;

@interface PlaceValue : ToolScene
{

    ToolHost *toolHost;
    NSDictionary *problemDef;
    
    BOOL touching;
    BOOL potentialTap;
    
    CGPoint winL;
    float cx, cy, lx, ly;
    
    CCLayer *renderLayer;
    CCLayer *countLayer;
    
    CCLabelTTF *problemSubLabel;
    CCLabelTTF *problemCompleteLabel;
    CCLabelTTF *countLabel;
    CCLabelTTF *countLabelBlock;

    // GameWorld setup

    int ropesforColumn;
    int rows;    
    int currentColumnIndex;
    float defaultColumn;
    float columnBaseValue;
    float firstColumnValue;
    float totalObjectValue;
    float xStartOffset;
    float kPropXColumnSpacing;
    int numberOfColumns;    
    
    // GameWorld options
    
    BOOL showCount;
    BOOL showValue;
    BOOL showBaseSelection;
    BOOL showCountOnBlock;
    BOOL showColumnHeader;
    //BOOL disableCageAdd;
    //BOOL disableCageDelete;
    BOOL showReset;
    BOOL fadeCount;
    BOOL allowDeselect;
    BOOL allowPanning;
    BOOL allowCondensing;
    BOOL allowMulching;
    
    NSString *posCageSprite;
    NSString *negCageSprite;
    NSString *pickupSprite;
    NSString *proximitySprite;

    NSString *solutionDisplayText;
    NSString *incompleteDisplayText;
    NSDictionary *showCustomColumnHeader;
    
    NSMutableArray *columnInfo;
    
    NSArray *problemFiles;
    int currentProblemIndex;
    
    NSDictionary *solutionsDef;
    NSDictionary *columnSprites;
    NSDictionary *columnCages;
    NSDictionary *columnNegCages;
    NSDictionary *columnRows;
    NSDictionary *columnRopes;
    NSDictionary *columnCagePosDisableAdd;
    NSDictionary *columnCagePosDisableDel;
    NSDictionary *columnCageNegDisableAdd;
    NSDictionary *columnCageNegDisableDel;
    
    DWGameWorld *gw;

    CGPoint touchStartPos;
    CGPoint touchEndPos;
    
    NSArray *initObjects;
    
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    ProblemEvalMode evalMode;
    
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    BOOL autoHideStatusLabel;
    float timeToHideStatusLabel;
    
    int lastCount;
    int totalCountedInProblem;
    float maxSumReachedByUser;
    float expectedCount;
    float totalCount;
    
    CCSprite *condensePanel;
    CCSprite *mulchPanel;
    
    CGRect boundingBoxCondense;
    CGRect boundingBoxMulch;
    
    BOOL inBlockTransition;
    BOOL inCondenseArea;
    BOOL inMulchArea;
    
    //reference to cages
    NSMutableArray *allCages;
    
    NSMutableDictionary *boundCounts;
}

-(void)populateGW;
-(void)setupProblem;
-(void)setupBkgAndTitle;
-(void)readPlist:(NSDictionary*)pdef;
-(void)problemStateChanged;
-(void)evalProblem;
-(void)doWinning;
-(BOOL)evalProblemCountSeq:(NSString*)problemType;
-(void)calcProblemCountSequence;
-(void)calcProblemTotalCount;
-(BOOL)evalProblemTotalCount:(NSString*)problemType;
-(void)evalProblemMatrixMatch;
-(void)snapLayerToPosition;

-(BOOL)doCondenseFromLocation:(CGPoint)location;
-(BOOL)doMulchFromLocation:(CGPoint)location;
-(BOOL)doTransitionWithIncrement:(int)incr;

@end