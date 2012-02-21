//
//  ToolHost.h
//  belugapad
//
//  Created by Gareth Jenkins on 20/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "cocos2d.h"

@class Daemon;
@class ToolScene;

@interface ToolHost : CCLayer
{
    float cx, cy, lx, ly;
    
    NSArray *problemList;
    int problemIndex;
    
    CCLayer *perstLayer;
    CCLayer *backgroundLayer;

    CCLayer *toolBackLayer;
    CCLayer *toolForeLayer;
    
    ToolScene *currentTool;
}

@property (retain) Daemon *Zubi;

+(CCScene *) scene;

-(NSDictionary*)getNextProblem;
-(void)loadTestPipeline;
-(void) loadTool;
-(void) addToolForeLayer:(CCLayer *) foreLayer;
-(void) addToolBackLayer:(CCLayer *) backLayer;
-(void) populatePerstLayer;
-(void) gotoNewProblem;

-(void)doUpdateOnTick:(ccTime)delta;
-(void)doUpdateOnSecond:(ccTime)delta;
-(void)doUpdateOnQuarterSecond:(ccTime)delta;

-(void)recurseSetIntroFor:(CCNode*)node withTime:(float)time forTag:(int)tag;
-(void)stageIntroActions;

@end
