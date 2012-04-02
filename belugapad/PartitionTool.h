//
//  PartitionTool.h
//  belugapad
//
//  Created by David Amphlett on 29/03/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "ToolConsts.h"
#import "ToolScene.h"

@class DWPartitionObjectGameObject;
@class DWPartitionRowGameObject;
@class DWPartitionStoreGameObject;

@interface PartitionTool : ToolScene
{
    ToolHost *toolHost;
    DWGameWorld *gw;
    NSDictionary *problemDef;
    
    CGPoint winL;
    float cx, cy, lx, ly;

    CCLayer *renderLayer;
}

-(void)readPlist;
-(void)populateGW;
@end
