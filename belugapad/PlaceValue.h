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
@class DWGameObject;
@class SGGameWorld;
@class DWPlaceValueNetGameObject;
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
    
    CCLabelTTF *problemSubLabel;
    CCLabelTTF *problemCompleteLabel;
    CCLabelTTF *countLabel;
    CCLabelTTF *sumLabel;
    CCLabelTTF *countLabelBlock;
    NSMutableArray *totalCountSprites;
    NSMutableArray *userAddedBlocks;
    NSMutableArray *userAddedBlocksLastCount;
    NSMutableArray *initBlockValueForColumn;
    NSMutableArray *arrowsForColumn;

    // GameWorld setup
    
    BOOL isProblemComplete;

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
    BOOL showMoreOrLess;
    
    // GameWorld options
    
    BOOL showCount;
    BOOL showValue;
    BOOL showBaseSelection;
    BOOL showCountOnBlock;
    BOOL showColumnHeader;
    BOOL showColumnTotalCount;
    BOOL showColumnUserCount;
    BOOL justMulched;
    BOOL thisCageWontTakeMe;
    BOOL cageHasDropped;
    //BOOL disableCageAdd;
    //BOOL disableCageDelete;
    BOOL showReset;
    BOOL fadeCount;
    BOOL allowDeselect;
    BOOL allowPanning;
    BOOL allowCondensing;
    BOOL allowMulching;
    BOOL hasMovedBlock;
    BOOL hasMovedLayer;
    BOOL disableAudioCounting;
    BOOL countUserBlocks;
    BOOL autoBaseSelection;
    
    

    NSString *posCageSprite;
    NSString *negCageSprite;
    NSString *pickupSprite;
    NSString *proximitySprite;

    NSString *solutionDisplayText;
    NSString *incompleteDisplayText;
    NSDictionary *showCustomColumnHeader;
    
    NSMutableArray *columnInfo;
    NSMutableArray *blocksToCreate;
    NSMutableArray *currentBlockValues;
    NSMutableArray *blockLabels;
    
    NSArray *problemFiles;
    int currentProblemIndex;
    
    NSDictionary *solutionsDef;
    NSDictionary *columnSprites;
    NSDictionary *columnCages;
    NSDictionary *columnRows;
    NSDictionary *columnRopes;
    NSDictionary *columnCagePosDisableAdd;
    NSDictionary *columnCagePosDisableDel;
    NSDictionary *columnCageNegDisableAdd;
    NSDictionary *columnCageNegDisableDel;
    NSDictionary *multipleBlockPickup;
    NSDictionary *multipleBlockPickupDefaults;
    NSMutableDictionary *multipleBlockMax;
    NSMutableDictionary *multipleBlockMin;
    
    
    DWGameWorld *gw;
    SGGameWorld *sgw;

    CGPoint touchStartPos;
    CGPoint touchEndPos;
    
    NSArray *initObjects;
    
    BOOL isNegativeProblem;
    
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    ProblemEvalMode evalMode;
    
    float timeToAutoMoveToNextProblem;
    BOOL autoMoveToNextProblem;
    BOOL autoHideStatusLabel;
    BOOL showMultipleControls;
    float timeToHideStatusLabel;
    float timeSinceInteractionOrShake;
    BOOL hasRunInteractionFeedback;
    
    int lastCount;
    int totalCountedInProblem;
    int lastPickedUpBlockCount;
    float maxSumReachedByUser;
    float expectedCount;
    float totalCount;
    float lastTotalCount;
    
    int cageDefaultValue;
    BOOL explodeMode;
    BOOL shouldUpdateLabels;
    
    CCSprite *condensePanel;
    CCSprite *mulchPanel;
    
    NSString *columnCountTotalType;
    
    CGRect boundingBoxCondense;
    CGRect boundingBoxMulch;
    CGRect noDragAreaTop;
    CGRect noDragAreaBottom;
    
    CGPoint previousLocation;
    
    BOOL inBlockTransition;
    BOOL inCondenseArea;
    BOOL inMulchArea;
    
    BOOL changedBlockCountOrValue;
    
    NSString *solutionType;
    
    //reference to cages
    NSMutableArray *allCages;
    // reference to plus and minus sprites and labels for block creation
    NSMutableArray *multiplePlusSprites;
    NSMutableArray *multipleMinusSprites;
    NSMutableArray *multipleLabels;
    
    NSMutableDictionary *boundCounts;
    
    // use this array in a case we need to drag more than 1  object
    NSMutableArray *pickupObjects;
//    DWPlaceValueNetGameObject *lastNet;
    
    BOOL isBasePickup;
    BOOL hasMovedBasePickup;
    
    BOOL debugLogging;
    int thisLog;
    
}

-(void)populateGW;
-(void)setupProblem;
-(void)setupBkgAndTitle;
-(void)readPlist:(NSDictionary*)pdef;
-(void)problemStateChanged;
-(void)evalProblem;
-(void)doWinning;
-(BOOL)evalProblemCountSeq;
-(void)calcProblemCountSequence;
-(void)calcProblemTotalCount;
-(BOOL)evalProblemTotalCount;
-(BOOL)evalProblemMatrixMatch;
-(void)checkForMultipleControlTouchesAt:(CGPoint)thisLocation;
-(void)checkForBlockValueTouchesAt:(CGPoint)thisLocation;
-(void)checkAndChangeCageSpritesForMultiple;
-(void)checkAndChangeCageSpritesForNegative;
-(void)switchSpritesBack;
-(void)createCondenseAndMulchBoxes;
-(void)snapLayerToPosition;
-(void)checkMountPositionsForBlocks;
-(void)flipToBaseSelection;
-(int)freeSpacesOnGrid:(int)thisGrid;
-(void)tintGridColour:(ccColor3B)toThisColour;
-(void)tintGridColour:(int)thisGrid toColour:(ccColor3B)toThisColour;
-(void)resetPickupObjectPos;
-(void)resetObjectStates;
-(BOOL)doCondenseFromLocation:(CGPoint)location;
-(BOOL)doMulchFromLocation:(CGPoint)location;
-(BOOL)doTransitionWithIncrement:(int)incr;
-(void)setTouchVarsToOff;

@end