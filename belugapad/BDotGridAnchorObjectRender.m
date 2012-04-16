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
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        if(!mySprite) 
        {
            [self setSprite];     
        }
    }
    
    if(messageType==kDWupdateSprite)
    {

        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        if(!mySprite) { 
            [self setSprite];
        }

        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
    }
    if(messageType==kDWdismantle)
    {
        CCSprite *s=[[gameObject store] objectForKey:MY_SPRITE];
        [[s parent] removeChild:s cleanup:YES];
    }
    
    if(messageType==kDWswitchSelection)
    {
        [self switchSelection];
    }
}



-(void)setSprite
{    
    NSString *spriteFileName=[[NSString alloc]init];
    //[[gameWorld GameSceneLayer] addChild:mySprite z:1];

        
    spriteFileName=@"/images/dotgrid/anchor.png";
    anch.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    [anch.mySprite setPosition:anch.Position];
    [anch.mySprite setScale:0.5f];
    
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [anch.mySprite setTag:2];
        [anch.mySprite setOpacity:0];
    }
    
    if(anch.StartAnchor)
    {
        [anch.mySprite setColor:ccc3(255, 0, 0)];
    }

    

    [[gameWorld Blackboard].ComponentRenderLayer addChild:anch.mySprite z:2];
    
}

-(void)switchSelection
{
    if(anch.CurrentlySelected)
    {
        if(anch.StartAnchor) [anch.mySprite setColor:ccc3(255,0,0)];
        else [anch.mySprite setColor:ccc3(255,255,255)];
        anch.CurrentlySelected=NO;
        [gameWorld.Blackboard.SelectedObjects removeObject:anch];
        NSLog(@"add current sprite");
    }
    else {
        if(anch.StartAnchor) [anch.mySprite setColor:ccc3(255,0,86)];
        else [anch.mySprite setColor:ccc3(120,125,255)];
        anch.CurrentlySelected=YES;
        [gameWorld.Blackboard.SelectedObjects addObject:anch];
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
