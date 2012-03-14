//
//  BNLineRamblerRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNLineRamblerRender.h"
#import "DWRamblerGameObject.h"
#import "global.h"

static float kIndicatorYOffset=15.0f;

@implementation BNLineRamblerRender

-(BNLineRamblerRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNLineRamblerRender*)[super initWithGameObject:aGameObject withData:data];
    
    ramblerGameObject=(DWRamblerGameObject*)gameObject;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        [self setupStuff];
    }
}

-(void)setupStuff
{
    int baseSegs=(gameWorld.Blackboard.hostCX * 2) / ramblerGameObject.DefaultSegmentSize + 4;
    
    //to hack full screen offset scrolling without adjusting actual offset
    baseSegs=baseSegs * 4;

    assBlankSegments=[[NSMutableArray alloc] init];
    assLineSegments=[[NSMutableArray alloc] init];
    assIndicators=[[NSMutableArray alloc] init];
    
    for (int i=0; i<baseSegs; i++) {
        CCSprite *blank=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/seg_blank.png")];
        [blank setVisible:NO];
        [assBlankSegments addObject:blank];
        [gameWorld.Blackboard.ComponentRenderLayer addChild:blank];
        
        CCSprite *line=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/seg_solid.png")];
        [line setVisible:NO];
        [assLineSegments addObject:line];
        [gameWorld.Blackboard.ComponentRenderLayer addChild:line];
        
        CCSprite *ind=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/indicator_bar.png")];
        [ind setVisible:NO];
        [assIndicators addObject:ind];
        [gameWorld.Blackboard.ComponentRenderLayer addChild:ind];   
    }
    
    assStartTerminator=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/line_stop.png")];
    [assStartTerminator setVisible:NO];
    [gameWorld.Blackboard.ComponentRenderLayer addChild:assStartTerminator];
    
    assEndTerminator=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/line_stop.png")];
    [assEndTerminator setVisible:NO];
    [gameWorld.Blackboard.ComponentRenderLayer addChild:assEndTerminator];
    
    
}

-(void)doUpdate:(ccTime)delta
{
    int segsInCX=(gameWorld.Blackboard.hostCX / ramblerGameObject.DefaultSegmentSize);
    
    //scale these up by three -- allows for full screen scroll in either direction without new draw
    float minValuePos=ramblerGameObject.Value - (segsInCX * 4);
    float maxValuePos=ramblerGameObject.Value + (segsInCX * 4);
    
    int assBlankIndex=0;
    int assLineIndex=0;
    int assIndicatorIndex=0;
    
    for (int iValue=minValuePos; iValue<=maxValuePos; iValue+=ramblerGameObject.CurrentSegmentValue) {
        
        float diffInValFromCentre=iValue-ramblerGameObject.Value;
        CGPoint segStartPos=CGPointMake(ramblerGameObject.Pos.x + ramblerGameObject.TouchXOffset + diffInValFromCentre * ramblerGameObject.DefaultSegmentSize, ramblerGameObject.Pos.y);
        CGPoint segStartPosForLine = CGPointMake(segStartPos.x + ramblerGameObject.DefaultSegmentSize / 2.0f, segStartPos.y);
        
        if(iValue<[ramblerGameObject.MinValue intValue])
        {
            //render as blank
            CCSprite *assBlank=[assBlankSegments objectAtIndex:assBlankIndex];
            [assBlank setVisible:YES];
            [assBlank setPosition:segStartPosForLine];
            
            assBlankIndex++;
        }
        
        if(iValue>=[ramblerGameObject.MinValue intValue] && iValue < [ramblerGameObject.MaxValue intValue])
        {
            //render as line
            CCSprite *assLine=[assLineSegments objectAtIndex:assLineIndex];
            [assLine setVisible:YES];
            [assLine setPosition:segStartPosForLine];
            
            assLineIndex++;
        }
        
        if(iValue>= [ramblerGameObject.MaxValue intValue])
        {
            //render as blank
            CCSprite *assBlank=[assBlankSegments objectAtIndex:assBlankIndex];
            [assBlank setVisible:YES];
            [assBlank setPosition:segStartPosForLine];
            
            assBlankIndex++;
        }
        
        //place start / end indicators
        if(iValue==[ramblerGameObject.MinValue intValue])
        {
            [assStartTerminator setVisible:YES];
            [assStartTerminator setPosition:segStartPos];
        }
        if(iValue==[ramblerGameObject.MaxValue intValue])
        {
            [assEndTerminator setVisible:YES];
            [assEndTerminator setPosition:segStartPos];
        }
        
        //render number indicator
        CCSprite *ind=[assIndicators objectAtIndex:assIndicatorIndex];
        [ind setVisible:YES];
        [ind setPosition:CGPointMake(segStartPos.x, segStartPos.y - kIndicatorYOffset)];

        //change opcaity for on-line and off-line items
        if(iValue>=[ramblerGameObject.MinValue intValue] && iValue <= [ramblerGameObject.MaxValue intValue])
        {
            [ind setOpacity:255];
        }
        else {
            [ind setOpacity:50];
        }
        
        assIndicatorIndex++;
        
    }
    
    //set invisible any remaining segements etc
    for (int i=assBlankIndex; i<[assBlankSegments count]; i++) {
        [[assBlankSegments objectAtIndex:i] setVisible:NO];
    }
    
    for (int i=assLineIndex; i<[assLineSegments count]; i++) {
        [[assLineSegments objectAtIndex:i] setVisible:NO];
    }
    
    for (int i=assIndicatorIndex; i<[assIndicators count]; i++) {
        [[assIndicators objectAtIndex:i] setVisible:NO];
    }
}

@end
