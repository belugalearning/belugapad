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
    
    int aCols[5];
    int bCols[5];
    int sCols[5];
    
    CCLabelTTF *aColLabels[5];
    CCLabelTTF *bColLabels[5];
    CCLabelTTF *sColLabels[5];
    CCLabelTTF *remLabels[5];
    
}
-(void)populateGW;
-(void)readPlist:(NSDictionary*)pdef;
@end
