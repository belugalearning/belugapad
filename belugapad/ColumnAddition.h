//
//  ColumnAddition.h
//  belugapad
//
//  Created by David Amphlett on 19/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "ToolScene.h"
#import "cocos2d.h"
#import "ToolConsts.h"

@class DWGameWorld;
@class Daemon;
@class ToolHost;

typedef enum
{
    kNoState=0,
    kNumberSelected=1,
    kNumberOperatorSelected=2,
    kNumberRemainder=3,
    kNumberRemainderDrag=4,
    kNumberRemainderPress=5
} currentToolState;

@interface ColumnAddition : ToolScene

{
    currentToolState toolState;
    ToolHost *toolHost;
    NSDictionary *problemDef;
    
    CGPoint winL;
    float cx, cy, lx, ly;
    
    DWGameWorld *gw;
    CCLayer *sumBoxLayer;
    
    // Problem state vars
    BOOL touching;
    
    int sourceA;
    int sourceB;
    int sum;
    int rem;
    
    float colSpacing;
    
    int aCols[5];
    int bCols[5];
    int sCols[5];
    int rCols[5];
    
    CCLabelTTF *aColLabels[5];
    CCLabelTTF *bColLabels[5];
    CCLabelTTF *sColLabels[5];
    CCLabelTTF *remLabels[5];
    //CCLabelTTF *lblOperator;
    CCSprite *btnOperator;
    CCSprite *lblRemainder;
    CGPoint lblRemainderPos;
    
    BOOL aColLabelSelected[5];
    BOOL aColLabelEnabled[5];
    BOOL bColLabelSelected[5];
    BOOL bColLabelEnabled[5];
    BOOL sColLabelSelected[5];
    BOOL lblOperatorSelected;
    BOOL lblOperatorActive;
    
    NSString *bkgOverlay;
    
}
-(void)populateGW;
-(void)readPlist:(NSDictionary*)pdef;
-(void)updateLabels;
-(void)deselectNumberAExcept:(int)thisNumber;
-(void)deselectNumberBExcept:(int)thisNumber;
-(void)switchOperator;
-(void)switchOperatorSprite;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
@end
