//
//  BNLineSelectorRender.m
//  belugapad
//
//  Created by David Amphlett on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "global.h"
#import "ToolScene.h"
#import "BNLineSelectorRender.h"
#import "DWSelectorGameObject.h"
#import "DWRamblerGameObject.h"

@implementation BNLineSelectorRender

-(BNLineSelectorRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNLineSelectorRender*)[super initWithGameObject:aGameObject withData:data];
    selector = (DWSelectorGameObject*)gameObject;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        selector.BasePos=selector.pos;
        
        [self setSprite];
    }
    if(messageType==kDWrenderSelection)
    {
        NSNumber *num=[payload objectForKey:@"VALUE"];
        [self renderLabelSelection:[num stringValue]];
    }
}

-(void)renderLabelSelection:(NSString*)labelText
{
    if(selectionLabel)
    {
        [[gameWorld GameScene].ForeLayer removeChild:selectionLabel cleanup:YES];
    }
    
    selectionLabel=[CCLabelTTF labelWithString:labelText fontName:GENERIC_FONT fontSize:40];
    [selectionLabel setPosition:CGPointMake(selector.BasePos.x, selector.BasePos.y+10)];
    [[gameWorld GameScene].ForeLayer addChild:selectionLabel];
}

-(void)doUpdate:(ccTime)delta
{
    if(selector.WatchRambler.RenderStitches && selector.WatchRambler.AutoStitchIncrement>0)
    {
        //move amount on x -- e.g. if moved past threshold
        float moveX=0;
        float moveY=0;
        float connectorOpacity=255;
        
        if(selector.WatchRambler.MinValue && selector.WatchRambler.Value <= [selector.WatchRambler.MinValue intValue] && selector.WatchRambler.TouchXOffset>0)
        {
            selector.WatchRambler.TouchXOffset=0;
            //moveX=-selector.WatchRambler.TouchXOffset;
        }
        else if(selector.WatchRambler.MaxValue && selector.WatchRambler.Value >= [selector.WatchRambler.MaxValue intValue] && selector.WatchRambler.TouchXOffset<0)
        {
            selector.WatchRambler.TouchXOffset=0;
            //moveX=-selector.WatchRambler.TouchXOffset;
        }
        else {
                
            //set Y offset of selector based on touchOffsetX of rambler
            float totalX=selector.WatchRambler.AutoStitchIncrement * selector.WatchRambler.DefaultSegmentSize;
            
            //tofu -- set this to pos diff of selector origin to line
            float totalY=100.0f;
            
            //get proportional distance moved on X
            float propX=fabsf(selector.WatchRambler.TouchXOffset) / totalX;
            
            
            //cap at 1 (never move selector below line)
            if(propX>1)
            {
                propX=1;
                moveX=fabsf(selector.WatchRambler.TouchXOffset) - totalX;
                
                //put move in negative space if touch was in positive space
                if(selector.WatchRambler.TouchXOffset>0)moveX*=-1;
                
                //reset touch offset to bound
                if(selector.WatchRambler.TouchXOffset<0) selector.WatchRambler.TouchXOffset=-totalX;
                else selector.WatchRambler.TouchXOffset=totalX;
            }
            
            //get offset on y
            moveY=totalY*propX;
            
            //get connector opacity
            connectorOpacity=255-255*propX;
        }
        
        //move position of selector
        selector.pos=CGPointMake(selector.BasePos.x - moveX, selector.BasePos.y - moveY);
        [mySprite setPosition:selector.pos];
        
        [connectorSprite setOpacity:connectorOpacity];
        [selectionLabel setOpacity:connectorOpacity];
    }
}

-(void)setSprite
{
    NSString *sname=[[gameObject store] objectForKey:RENDER_IMAGE_NAME];
    if(!sname) sname=@"selector.png";
    
    mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"/images/numberline/%@", sname]))];
    
    //tagged for staged introduction into problem
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [mySprite setTag:2];
        [mySprite setOpacity:0];
    }
    
    [mySprite setPosition:ccp(selector.pos.x, selector.pos.y)];
    
    
    //[[gameWorld GameScene].ForeLayer addChild:mySprite z:0];
    
    connectorSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/numberline/selector-connector.png")];
    [connectorSprite setPosition:CGPointMake(selector.pos.x, selector.pos.y-92)];
    [connectorSprite setTag:3];
    [connectorSprite setOpacity:0];
    //[[gameWorld GameScene].ForeLayer addChild:connectorSprite];
    
    
}


@end
