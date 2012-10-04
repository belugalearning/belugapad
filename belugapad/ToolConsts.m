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
const float kLabelTitleXMarginProp=0.87f;
const float kLabelTitleYOffsetHalfProp=1.47f;
const ccColor3B kLabelTitleColor={255, 255, 255};

const float kLabelCompleteYOffsetHalfProp=0.28f;
const ccColor3B kLabelCompleteColor={0, 255, 0};

const CGPoint kButtonNextToolPos={996, 735};

const float kPropXPauseButtonPadding=0.032f;
const float kPropXCommitButtonPadding=0.062f;
const CGRect kRectButtonCommit={{904, 648}, {120, 120}};
const CGRect kRectButtonReset={{944, 688}, {80, 80}};


const float kTimeToAutoMove=1.0f;
const float kTimeToShowProblemStatus=1.5f;
const float kTimeToFadeProblemStatus=1.0f;
const float kTimeToFadeButtonLabel=2.0f;

// originally used by placevalue for snap back to cage time

const float kTimeObjectSnapBack=0.25f;
const ccColor3B kLabelCountColor={255, 0, 0};


const ccColor3B kMetaQuestionLabelColor={255, 255, 170};
const ccColor3B kMetaAnswerLabelColorSelected={88, 88, 88};
const ccColor3B kMetaAnswerLabelColorDeselected={108, 108, 108};
const ccColor3B kMetaQuestionButtonSelected={240, 240, 240};
const ccColor3B kMetaQuestionButtonDeselected={255, 255, 255};

const float kMetaQuestionYOffsetPlaceValue=0.45f;
const float kMetaQuestionYOffsetBlockFloat=0.35f;
const float kMetaIncompleteLabelYOffset=0.65f;

// number picker
const float kNumberPickerSpacingFromDropboxEdge=1.85f;
const float kNumberPickerNumberFadeInTime=0.5f;
const float kNumberPickerNumberAnimateInTime=0.2f;
const float kNumberPickerNumberSpaceBetweenSpritesProp=0.005f;


const CGRect kPauseMenuLogOut={{8.0f,717.0f},{120.0f,43.0f}};
const CGRect kPauseMenuMenu={{374.0f,478.0f},{275.0f,80.0f}};
const CGRect kPauseMenuReset={{374.0f,378.0f},{275.0f,80.0f}};
const CGRect kPauseMenuContinue={{299.0f,213.0f},{424.0f,80.0f}};

const ccColor3B kNumberBondColour[10]={{242,225,210},{208,23,62},{88,172,50},{113,43,74},{251,208,48},{25,84,42},{28,28,29},{125,51,23},{6,36,102},{237,75,20}};
const ccColor3B kNumiconColour[10]={{191,255,193},{191,255,244},{223,191,255},{255,178,178},{204,240,255},{255,211,178},{254,255,204},{255,217,244},{220,244,222},{217,174,174}};


// fraction builder

const float kNumbersAlongFractionSlider=19;