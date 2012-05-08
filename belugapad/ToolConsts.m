//
//  ToolConsts.m
//  belugapad
//
//  Created by David Amphlett on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ToolConsts.h"


const GLubyte kDebugLabelOpacity=65;
const CGPoint kDebugProblemLabelPos={135, 755};

const float kScheduleUpdateLoopTFPS=60.0f;
const float kButtonToolbarHitBaseYOffset=720.0f;
const float kButtonNextToolHitXOffset=975.0f;


const float kLabelSubTitleYOffsetHalfProp=1.75f;
const float kLabelTitleYOffsetHalfProp=1.85f;
const ccColor3B kLabelTitleColor={255, 255, 255};

const float kLabelCompleteYOffsetHalfProp=0.28f;
const ccColor3B kLabelCompleteColor={0, 255, 0};

const CGPoint kButtonNextToolPos={996, 735};

const float kPropXCommitButtonPadding=0.048f;
const CGRect kRectButtonCommit={{944, 0}, {80, 80}};
const CGRect kRectButtonReset={{944, 688}, {80, 80}};


const float kTimeToAutoMove=1.0f;
const float kTimeToShowProblemStatus=1.5f;
const float kTimeToFadeProblemStatus=1.0f;
const float kTimeToFadeButtonLabel=2.0f;

// originally used by placevalue for snap back to cage time

const float kTimeObjectSnapBack=0.25f;
const ccColor3B kLabelCountColor={255, 0, 0};


const ccColor3B kMetaQuestionLabelColor={255, 255, 170};
const ccColor3B kMetaAnswerLabelColor={45, 65, 72};
const ccColor3B kMetaQuestionButtonSelected={0, 255, 0};
const ccColor3B kMetaQuestionButtonDeselected={255, 255, 255};

const float kMetaQuestionYOffsetPlaceValue=0.45f;
const float kMetaQuestionYOffsetBlockFloat=0.35f;
const float kMetaIncompleteLabelYOffset=0.65f;

const CGRect kPauseMenuMenu={{400.0f,477.5},{250.0f,45.0f}};
const CGRect kPauseMenuReset={{400.0f,395.5},{250.0f,45.0f}};
const CGRect kPauseMenuContinue={{400.0f,233.5f},{250.0f,45.0f}};