//
//  NLine.h
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ToolScene.h"
#import "cocos2d.h"
#import "ToolConsts.h"

@class DWGameWorld;
@class DWRamblerGameObject;
@class DWSelectorGameObject;
@class Daemon;
@class ToolHost;

@interface NLine : ToolScene
{
    ToolHost *toolHost;
    NSDictionary *problemDef;
    
    CGPoint winL;
    float cx, cy, lx, ly;
    
    DWGameWorld *gw;
    DWRamblerGameObject *rambler;
    DWSelectorGameObject *selector;
    
    // Problem state vars
    BOOL touching;
    BOOL inRamblerArea;
    
    // Problem definition vars
    ProblemRejectMode rejectMode;
    ProbjemRejectType rejectType;
    ProblemEvalMode evalMode;
    NSString *evalType;
    int evalInterval;
    NSArray *evalJumpSequence;
    
    BOOL evalAbsTarget;
    
    CCLabelTTF *problemDescLabel;

    CCLabelTTF *problemCompleteLabel;
    
    CCTexture2D *bubbleTexRegular;
    CCTexture2D *bubbleTexSelected;
    
    CCSprite *bubbleSprite;
    BOOL usedBubble;
    BOOL holdingBubble;
    float holdingBubbleOffset;
    int bubblePushDir;
    int lastBubbleLoc;
    int lastBubbleValue;
    int evalTarget;
    
    CGPoint lasttouch;
    
    int initStartVal;
    NSNumber *initMinVal;
    NSNumber *initMaxVal;
    int initSegmentVal;
    int initStartLoc;
    
    BOOL countOutLoudFromInitStartVal;
    
    float timeSinceInteractionOrShake;
    
    //for logging
    int logLastBubblePos;
    BOOL logBubbleDidMove;
    BOOL logBubbleDidMoveLine;
    
    int bubbleAtBounds;
    
    float touchResetX;
    int touchResetDir;
    
    BOOL enableAudioCounting;
    
    
    // == jump mode
    BOOL jumpMode;
    CGPoint stitchStartPos;
    float stitchOffsetX;
    CGPoint stitchEndPos;
    CGPoint stitchApexPos;
    BOOL drawStitchLine;
    BOOL drawStitchCurve;
    
    int jumpStartValue;
    BOOL hasSetJumpStartValue;
    
    // == markers
    NSMutableArray *markerValuePositions;
    
    //== frog mode
    BOOL frogMode;
    CCSprite *frogSprite;
    int lastFrogLoc;
    CCSprite *frogTargetSprite;
    
    
    float slideLineBy;
    
}

-(void)populateGW;
-(void)readPlist:(NSDictionary*)pdef;
-(float)metaQuestionTitleYLocation;
-(float)metaQuestionAnswersYLocation;
-(void)evalProblem;

@end
