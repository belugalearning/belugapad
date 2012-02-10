//
//  PlaceValue.h
//  belugapad
//
//  Created by David Amphlett on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "cocos2d.h"
@class DWGameWorld;
@class Daemon;

@interface PlaceValue : CCLayer
{
    BOOL touching;
    
    CGPoint winL;
    float cx, cy, lx, ly;
    
    CCLabelTTF *problemDescLabel;
    CCLabelTTF *problemSubLabel;
    CCLabelTTF *problemCompleteLabel;
    
    int numberofIntegerColumns;
    int numberofDecimalColumns;
    int ropesforColumn;
    int rows;
    float defaultColumn;
    float currentColumn;
    
    NSArray *problemFiles;
    int currentProblemIndex;
    
    NSArray *solutionsDef;
    
    DWGameWorld *gw;
    Daemon *daemon;
}

+(CCScene *)scene;
-(void)doUpdate:(ccTime)delta;
-(void)populateGW;
-(void)setupProblem;
-(void)setupBkgAndTitle;
-(void)listProblemFiles;
-(void)resetToNextProblem;
-(void)readPlist;
-(void)ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
-(void)ccTouchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
@end