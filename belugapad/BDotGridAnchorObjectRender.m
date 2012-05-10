//
//  BDotGridAnchorObjectRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDotGridAnchorObjectRender.h"
#import "DWDotGridAnchorGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"
#import "DWGameWorld.h"

@implementation BDotGridAnchorObjectRender

-(BDotGridAnchorObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDotGridAnchorObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    
    anch=(DWDotGridAnchorGameObject*)gameObject;
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        if(!anch.mySprite) 
        {
            [self setSprite];     
        }
    }
    
    if(messageType==kDWupdateSprite)
    {
        if(!anch.mySprite) { 
            [self setSprite];
        }

        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
    }
    if(messageType==kDWdismantle)
    {
        [[anch.mySprite parent] removeChild:anch.mySprite cleanup:YES];
    } 
    
    if(messageType==kDWswitchSelection)
    {
        //[self switchSelection];
    }
}



-(void)setSprite
{    
    if(!anch.Hidden)
    {
        NSString *spriteFileName=[[NSString alloc]init];
        //[[gameWorld GameSceneLayer] addChild:mySprite z:1];

            
        if(anch.StartAnchor)spriteFileName=@"/images/dotgrid/move.png";
        else spriteFileName=@"/images/dotgrid/anchor.png";
        anch.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
        [anch.mySprite setPosition:anch.Position];
        //[anch.mySprite setScale:0.5f];
        
        
        if(gameWorld.Blackboard.inProblemSetup)
        {
            [anch.mySprite setTag:2];
            [anch.mySprite setOpacity:0];
        }

        

        [[gameWorld Blackboard].ComponentRenderLayer addChild:anch.mySprite z:2];
    }
}

-(void)switchSelection
{
    if(anch.Disabled)
    {
        if(anch.StartAnchor) [anch.mySprite setColor:ccc3(255,0,0)];
        else [anch.mySprite setColor:ccc3(255,255,255)];
        [gameWorld.Blackboard.SelectedObjects removeObject:anch];
        NSLog(@"add current sprite");
    }
    else {
        if(anch.StartAnchor) [anch.mySprite setColor:ccc3(255,0,86)];
        else [anch.mySprite setColor:ccc3(120,125,255)];
        [gameWorld.Blackboard.SelectedObjects addObject:anch];
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
