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

@interface ColumnAddition : ToolScene

{
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
    
    int aCols[4];
    int bCols[4];
    int sCols[4];
    
    CCLabelTTF *aColLabels[4];
    CCLabelTTF *bColLabels[4];
    CCLabelTTF *sColLabels[4];
    CCLabelTTF *remLabels[4];
    
}
-(void)populateGW;
-(void)readPlist:(NSDictionary*)pdef;
@end
