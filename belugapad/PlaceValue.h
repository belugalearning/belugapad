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
    
    CCLabelTTF *problemDescLabel;
    CCLabelTTF *problemSubLabel;
    CCLabelTTF *problemCompleteLabel;
    
    int numberofIntegerColumns;
    int numberofDecimalColumns;
    int ropesforColumn;
    int rows;
    float defaultColumn;
    float currentColumn;
    
    NSArray *problemFiles;
    int currentProblemIndex;
    
    NSDictionary *solutionsDef;
    
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
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
@end