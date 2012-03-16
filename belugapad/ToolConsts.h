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
    kProblemEvalAuto=0,
    kProblemEvalOnCommit=1
} ProblemEvalMode;

extern const GLubyte kDebugLabelOpacity;
extern const CGPoint kDebugProblemLabelPos;

extern const float kScheduleUpdateLoopTFPS;
extern const float kButtonToolbarHitBaseYOffset;
extern const float kButtonNextToolHitXOffset;
extern const float kLabelSubTitleYOffsetHalfProp;
extern const float kLabelTitleYOffsetHalfProp;
extern const ccColor3B kLabelTitleColor;
extern const float kLabelCompleteYOffsetHalfProp;
extern const ccColor3B kLabelCompleteColor;


extern const float kTimeToAutoMove;
extern const float kTimeToFadeButtonLabel;

extern const float kPropXCommitButtonPadding;
extern const CGRect kRectButtonCommit;
extern const CGRect kRectButtonReset;
extern const CGPoint kButtonNextToolPos;
extern const float kTimeObjectSnapBack;
extern const ccColor3B kLabelCountColor;

extern const ccColor3B kMetaQuestionLabelColor;
extern const ccColor3B kMetaAnswerLabelColor;
extern const ccColor3B kMetaQuestionButtonSelected;
extern const ccColor3B kMetaQuestionButtonDeselected;

extern const float kMetaQuestionYOffsetPlaceValue;
extern const float kMetaQuestionYOffsetBlockFloat;
extern const float kMetaIncompleteLabelYOffset;

extern const CGRect kPauseMenuMenu;
extern const CGRect kPauseMenuReset;
extern const CGRect kPauseMenuContinue;