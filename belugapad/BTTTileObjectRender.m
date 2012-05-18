//
//  BDotGridAnchorObjectRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BTTTileObjectRender.h"
#import "DWTTTileGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"
#import "DWGameWorld.h"

@implementation BTTTileObjectRender

-(BTTTileObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BTTTileObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    
    tile=(DWTTTileGameObject*)gameObject;
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        if(!tile.mySprite) 
        {
            [self setSprite];     
        }
    }
    
    if(messageType==kDWupdateSprite)
    {
        if(!tile.mySprite) { 
            [self setSprite];
        }

        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
    }
    if(messageType==kDWdismantle)
    {
        [[tile.mySprite parent] removeChild:tile.mySprite cleanup:YES];
    } 
    
    if(messageType==kDWswitchSelection)
    {
        //[self switchSelection];
    }
}



-(void)setSprite
{    

        NSString *spriteFileName=[[NSString alloc]init];
        //[[gameWorld GameSceneLayer] addChild:mySprite z:1];

            
        spriteFileName=@"/images/timestables/tile85.png";
        tile.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
        [tile.mySprite setPosition:tile.Position];
        //[anch.mySprite setScale:0.5f];
        
        if(tile.Disabled)[tile.mySprite setColor:ccc3(40,40,40)];
        
        if(gameWorld.Blackboard.inProblemSetup)
        {
            [tile.mySprite setTag:2];
            [tile.mySprite setOpacity:0];
        }

        

        [[gameWorld Blackboard].ComponentRenderLayer addChild:tile.mySprite z:2];

}

-(void)switchSelection
{
    if(tile.Disabled)
    {
        [gameWorld.Blackboard.SelectedObjects removeObject:tile];
    }
    else {
        [gameWorld.Blackboard.SelectedObjects addObject:tile];
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
