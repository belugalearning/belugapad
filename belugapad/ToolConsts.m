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
const CGRect kRectButtonCommit={{944, 700}, {80, 120}};
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
const CGRect kPauseMenuMenu={{410.0f,458.0f},{200.0f,85.0f}};
const CGRect kPauseMenuReset={{455.0f,358.0f},{120.0f,100.0f}};
const CGRect kPauseMenuContinue={{410.0f,268.0f},{210.0f,90.0f}};
const CGRect kPauseMenuMute={{750.0f,228.0f},{85.0f,80.0f}};

const ccColor3B kNumberBondColour[10]={{128,124,125},{216,12,52},{87,176,37},{230,51,131},{229,196,34},{49,142,76},{73,71,71},{166,54,198},{13,86,143},{241,72,0}};
const ccColor3B kNumiconColour[10]={{191,255,193},{191,255,244},{223,191,255},{255,178,178},{204,240,255},{255,211,178},{254,255,204},{255,217,244},{220,244,222},{217,174,174}};
const ccColor3B kBTXEColour[8]={{145,193,48},{245,82,82},{201,99,231},{244,167,47},{241,84,151},{19,189,183},{76,164,205},{239,224,55}};
const ccColor3B kLongDivColour[4]={{145,193,48},{243,157,7},{201,99,231},{244,167,47}};

// fraction builder

const float kNumbersAlongFractionSlider=19;


// distribution tool
const float kShapeValue001=0.01f;
const float kShapeValue01=0.1f;
const float kShapeValue1=1.0f;
const float kShapeValue10=10.0f;
const float kShapeValue100=100.0f;
const float kDistanceBetweenBlocks=62.0f;