//
//  ToolConsts.h
//  belugapad
//
//  Created by David Amphlett on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BLMath.h"

typedef enum {
    kProblemRejectNever=0,
    kProblemRejectOnCommit=1,
    kProblemRejectOnAction=2
} ProblemRejectMode;

typedef enum {
    kProblemResetOnReject=0,
    kProblemAutomatedTransition=1
} ProbjemRejectType;

typedef enum {
    kProblemEvalAuto=0,
    kProblemEvalOnCommit=1
} ProblemEvalMode;

typedef enum {
    kOperatorAdd=0,
    kOperatorSub=1,
    kOperatorMul=2,
    kOperatorDiv=3
} OperatorMode;

extern const GLubyte kDebugLabelOpacity;
extern const CGPoint kDebugProblemLabelPos;

extern const float kScheduleUpdateLoopTFPS;
extern const float kButtonToolbarHitBaseYOffset;
extern const float kButtonNextToolHitXOffset;
extern const float kLabelTitleXMarginProp;
extern const float kLabelSubTitleYOffsetHalfProp;
extern const float kLabelTitleYOffsetHalfProp;
extern const ccColor3B kLabelTitleColor;
extern const float kLabelCompleteYOffsetHalfProp;
extern const ccColor3B kLabelCompleteColor;


extern const float kTimeToAutoMove;
const float kTimeToShowProblemStatus;
const float kTimeToFadeProblemStatus;
extern const float kTimeToFadeButtonLabel;

extern const float kPropXPauseButtonPadding;
extern const float kPropXCommitButtonPadding;
extern const CGRect kRectButtonCommit;
extern const CGRect kRectButtonReset;
extern const CGPoint kButtonNextToolPos;
extern const float kTimeObjectSnapBack;
extern const ccColor3B kLabelCountColor;

extern const ccColor3B kMetaQuestionLabelColor;
extern const ccColor3B kMetaAnswerLabelColorSelected;
extern const ccColor3B kMetaAnswerLabelColorDeselected;
extern const ccColor3B kMetaQuestionButtonSelected;
extern const ccColor3B kMetaQuestionButtonDeselected;

extern const float kMetaQuestionYOffsetPlaceValue;
extern const float kMetaQuestionYOffsetBlockFloat;
extern const float kMetaIncompleteLabelYOffset;

// number picker
extern const float kNumberPickerSpacingFromDropboxEdge;
extern const float kNumberPickerNumberFadeInTime;
extern const float kNumberPickerNumberAnimateInTime;


extern const CGRect kPauseMenuMenu;
extern const CGRect kPauseMenuReset;
extern const CGRect kPauseMenuContinue;
extern const CGRect kPauseMenuLogOut;

extern const ccColor3B kNumberBondColour[10];
extern const ccColor3B kNumiconColour[10];
extern const ccColor3B kBTXEColour[8];
extern const ccColor3B kLongDivColour[4];

// fraction builder

extern const float kNumbersAlongFractionSlider;


//distribution tool
extern const float kShapeValue001;
extern const float kShapeValue01;
extern const float kShapeValue1;
extern const float kShapeValue10;
extern const float kShapeValue100;
extern const float kDistanceBetweenBlocks;