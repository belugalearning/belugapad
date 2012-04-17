//
//  BDotGridTileObjectRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDotGridTileObjectRender.h"
#import "DWDotGridTileGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"

@implementation BDotGridTileObjectRender

-(BDotGridTileObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDotGridTileObjectRender*)[super initWithGameObject:aGameObject withData:data];
    tile=(DWDotGridTileGameObject*)gameObject;
    
    //init pos x & y in case they're not set elsewhere
    
    
    
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
            [self setSpritePos:NO];            
        }
    }
    
    if (messageType==kDWmoveSpriteToPosition) {
        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
        [self setSpritePos:useAnimation];
    }
    if(messageType==kDWupdateSprite)
    {
        
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        if(!mySprite) { 
            [self setSprite];
        }
        
        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
        [self setSpritePos:useAnimation];
    }
    if(messageType==kDWdismantle)
    {
        CCSprite *s=[[gameObject store] objectForKey:MY_SPRITE];
        [[s parent] removeChild:s cleanup:YES];
    }
}



-(void)setSprite
{    
    NSString *spriteFileName=[[NSString alloc]init];
    //[[gameWorld GameSceneLayer] addChild:mySprite z:1];
    
    // check the requested tile type, then like, set our sprite to reflect this
    if(tile.tileType==kTopLeft)
    {
        spriteFileName=@"/images/dotgrid/tile-corner.png";
        [tile.mySprite setRotation:0.0f];
    }
    if(tile.tileType==kTopRight)
    {
        spriteFileName=@"/images/dotgrid/tile-corner.png";
        [tile.mySprite setRotation:90.0f];
    }
    if(tile.tileType==kBottomLeft)
    {
        spriteFileName=@"/images/dotgrid/tile-corner.png";
        [tile.mySprite setRotation:270.0f];
    }
    if(tile.tileType==kBottomRight)
    {
        spriteFileName=@"/images/dotgrid/tile-corner.png";
        [tile.mySprite setRotation:180.0f];
    }
    if(tile.tileType==kBorderLeft)
    {
        spriteFileName=@"/images/dotgrid/tile-border-single.png";
        [tile.mySprite setRotation:0.0f];
    }
    if(tile.tileType==kBorderRight)
    {
        spriteFileName=@"/images/dotgrid/tile-border-single.png";
        [tile.mySprite setRotation:180.0f];
    }
    if(tile.tileType==kBorderTop)
    {
        spriteFileName=@"/images/dotgrid/tile-border-single.png";
        [tile.mySprite setRotation:90.0f];
    }
    if(tile.tileType==kBorderBottom)
    {
        spriteFileName=@"/images/dotgrid/tile-border-single.png";
        [tile.mySprite setRotation:270.0f];
    }
    if(tile.tileType==kNoBorder)
    {
        spriteFileName=@"/images/dotgrid/tile-border-none.png";
    }
    
    
    
    tile.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    [tile.mySprite setPosition:tile.Position];
    
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [tile.mySprite setTag:2];
        [tile.mySprite setOpacity:0];
    }
    
    
    
    
    [[gameWorld Blackboard].ComponentRenderLayer addChild:tile.mySprite z:2];
}

-(void)setSpritePos:(BOOL) withAnimation
{
    
    
}

-(void) dealloc
{
    [super dealloc];
}

@end
