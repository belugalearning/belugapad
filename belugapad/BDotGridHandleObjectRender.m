//
//  BDotGridHandleObjectRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDotGridHandleObjectRender.h"
#import "DWDotGridHandleGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"

@implementation BDotGridHandleObjectRender

-(BDotGridHandleObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDotGridHandleObjectRender*)[super initWithGameObject:aGameObject withData:data];
    handle=(DWDotGridHandleGameObject*)gameObject;
    
    //init pos x & y in case they're not set elsewhere
    
    
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        CCSprite *mySprite=handle.mySprite;
        if(!mySprite) 
        {
            [self setSprite];
            [self setSpritePos];            
        }
    }
    
    if (messageType==kDWmoveSpriteToPosition) {
        
        [self setSpritePos];
    }
    if(messageType==kDWupdateSprite)
    {
        
        if(!handle.mySprite) { 
            [self setSprite];
        }
        
        [self setSpritePos];
    }
    if(messageType==kDWdismantle)
    {
        [[handle.mySprite parent] removeChild:handle.mySprite cleanup:YES];
    }
}



-(void)setSprite
{    
    NSString *spriteFileName=[[NSString alloc]init];

    NSLog(@"type of sprite: %d", handle.handleType);
    
    if(handle.handleType==kMoveHandle) spriteFileName=@"/images/dotgrid/move.png";
    if(handle.handleType==kResizeHandle) spriteFileName=@"/images/dotgrid/resize.png";
    
    NSLog(@"file: %@", spriteFileName);
    
    handle.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    [handle.mySprite setPosition:handle.Position];
    //[mySprite setScale:0.3f];
    
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [handle.mySprite setTag:2];
        [handle.mySprite setOpacity:0];
    }
    
    
    
    [[gameWorld Blackboard].ComponentRenderLayer addChild:handle.mySprite z:10];
    
    [spriteFileName release];
}

-(void)setSpritePos
{
    [handle.mySprite setPosition:handle.Position];
}

-(void) dealloc
{
    [super dealloc];
}

@end
