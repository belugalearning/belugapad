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
    int baseSegs=(gameWorld.Blackboard.hostCX * 2) / ramblerGameObject.DefaultSegmentSize + 2;

    assBlankSegments=[[NSMutableArray alloc] init];
    assLineSegments=[[NSMutableArray alloc] init];
    assIndicators=[[NSMutableArray alloc] init];
    
    for (int i=0; i<baseSegs; i++) {
        CCSprite *blank=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/seg_blank.png")];
        [blank setVisible:NO];
        [assBlankSegments addObject:blank];
        [blank release];
        
        CCSprite *line=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/seg_solid.png")];
        [line setVisible:NO];
        [assLineSegments addObject:line];
        [line release];
        
        CCSprite *ind=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/indicator_bar.png")];
        [ind setVisible:NO];
        [assIndicators addObject:ind];
        [ind release];
    }
}

-(void)doUpdate:(ccTime)delta
{
    int segsInCX=(gameWorld.Blackboard.hostCX / ramblerGameObject.DefaultSegmentSize);
    
    float minValuePos=ramblerGameObject.Value - (segsInCX + 1);
    float maxValuePos=ramblerGameObject.Value + (segsInCX + 1);
    
    int assBlankIndex=0;
    int assLineIndex=0;
    int assIndicatorIndex=0;
    
    for (int iValue=minValuePos; iValue<=maxValuePos; iValue+=ramblerGameObject.CurrentSegmentValue) {
        
        float diffInValFromCentre=iValue-ramblerGameObject.Value;
        CGPoint segStartPos=CGPointMake(ramblerGameObject.Pos.x + diffInValFromCentre * ramblerGameObject.DefaultSegmentSize, ramblerGameObject.Pos.y);
        
        if(iValue<[ramblerGameObject.MinValue intValue])
        {
            //render as blank
            CCSprite *assBlank=[assBlankSegments objectAtIndex:assBlankIndex];
            [assBlank setVisible:YES];
            [assBlank setPosition:segStartPos];
            
            assBlankIndex++;
        }
        
        if(iValue>=[ramblerGameObject.MinValue intValue] && iValue < [ramblerGameObject.MaxValue intValue])
        {
            //render as line
            CCSprite *assLine=[assLineSegments objectAtIndex:assLineIndex];
            [assLine setVisible:YES];
            [assLine setPosition:segStartPos];
            
            assLineIndex++;
        }
        
        if(iValue>= [ramblerGameObject.MaxValue intValue])
        {
            //render as blank
            CCSprite *assBlank=[assBlankSegments objectAtIndex:assBlankIndex];
            [assBlank setVisible:YES];
            [assBlank setPosition:segStartPos];
            
            assBlankIndex++;
        }
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
