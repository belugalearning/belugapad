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
    ProblemEvalMode evalMode;
    CCLabelTTF *problemDescLabel;

    CCLabelTTF *problemCompleteLabel;
}

-(void)populateGW;
-(void)readPlist:(NSDictionary*)pdef;

-(BOOL)evalProblem;

@end
