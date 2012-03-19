//
//  ColumnAddition.m
//  belugapad
//
//  Created by David Amphlett on 19/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ColumnAddition.h"
#import "ToolHost.h"
#import "ToolScene.h"
#import "global.h"
#import "BLMath.h"
#import "SimpleAudioEngine.h"
#import "ToolConsts.h"
#import "DWGameWorld.h"
#import "Daemon.h"
#import "NLineConsts.h"
#import "BAExpressionHeaders.h"
#import "BAExpressionTree.h"
#import "BATQuery.h"
#import "ColumnAdditionConsts.h"

@implementation ColumnAddition
-(id)initWithToolHost:(ToolHost *)host andProblemDef:(NSDictionary *)pdef
{
    toolHost=host;
    problemDef=pdef;
    
    if(self=[super init])
    {
        //this will force override parent setting
        //TODO: is multitouch actually required on this tool?
        [[CCDirector sharedDirector] openGLView].multipleTouchEnabled=YES;
        
        CGSize winsize=[[CCDirector sharedDirector] winSize];
        winL=CGPointMake(winsize.width, winsize.height);
        lx=winsize.width;
        ly=winsize.height;
        cx=lx / 2.0f;
        cy=ly / 2.0f;
        gw = [[DWGameWorld alloc] initWithGameScene:self];
        gw.Blackboard.inProblemSetup = YES;
        
        self.BkgLayer=[[[CCLayer alloc]init] autorelease];
        self.ForeLayer=[[[CCLayer alloc]init] autorelease];
        sumBoxLayer=[[[CCLayer alloc]init]autorelease];
        
        [toolHost addToolBackLayer:self.BkgLayer];
        [toolHost addToolForeLayer:self.ForeLayer];
        [self.ForeLayer addChild:sumBoxLayer];
        [sumBoxLayer setPosition:kSumBoxLayerPos];
        
        gw.Blackboard.ComponentRenderLayer=self.ForeLayer;
        
        [self readPlist:pdef];
        
        [self populateGW];
        
        [gw Blackboard].hostCX = cx;
        [gw Blackboard].hostCY = cy;
        [gw Blackboard].hostLX = lx;
        [gw Blackboard].hostLY = ly;
        
        [gw handleMessage:kDWsetupStuff andPayload:nil withLogLevel:0];
        
        gw.Blackboard.inProblemSetup = NO;
    }
    
    return self;
}

-(void)doUpdateOnTick:(ccTime)delta
{
	[gw doUpdate:delta];
    
}

-(void)populateGW
{
    colSpacing=kSumBoxWidth/6.0f;
    
    for(int i=0; i<5; i++)
    {
        sColLabels[i] = [CCLabelTTF labelWithString:@"#" fontName:PROBLEM_DESC_FONT fontSize:72.0f];
        float lblXPos=(i+1)*colSpacing;
        [sColLabels[i] setPosition:ccp(lblXPos, 500)];
        [sumBoxLayer addChild:sColLabels[i]];
    }
}

-(void)readPlist:(NSDictionary*)pdef
{
    sourceA = [[pdef objectForKey:NUMBER_A] intValue];
    sourceB = [[pdef objectForKey:NUMBER_B] intValue];
}


@end
