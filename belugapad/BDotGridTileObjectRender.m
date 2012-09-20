//
//  BDotGridTileObjectRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDotGridTileObjectRender.h"
#import "DWDotGridTileGameObject.h"
#import "DWDotGridAnchorGameObject.h"
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
        if(!tile.mySprite) 
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
        
        CCSprite *mySprite=tile.mySprite;
        if(!mySprite) { 
            [self setSprite];
        }
        
        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
        [self setSpritePos:useAnimation];
    }
    if(messageType==kDWdismantle)
    {
        CCSprite *s=tile.mySprite;
        
        if(tile.myAnchor)
        {
            DWDotGridAnchorGameObject *anch=tile.myAnchor;
            anch.tile=nil;
            tile.myAnchor=nil;
        }
        
        [[s parent] removeChild:s cleanup:YES];
        [gameWorld delayRemoveGameObject:tile];
    }
}



-(void)setSprite
{    
    NSString *spriteFileName=[[NSString alloc]init];
    //[[gameWorld GameSceneLayer] addChild:mySprite z:1];
    
    // check the requested tile type, then like, set our sprite to reflect this
    if(tile.tileType==kTopLeft)
    {
        spriteFileName=@"/images/dotgrid/tile-corner";
        [tile.mySprite setRotation:0.0f];
    }
    if(tile.tileType==kTopRight)
    {
        spriteFileName=@"/images/dotgrid/tile-corner";
        [tile.mySprite setRotation:90.0f];
    }
    if(tile.tileType==kBottomLeft)
    {
        spriteFileName=@"/images/dotgrid/tile-corner";
        [tile.mySprite setRotation:270.0f];
    }
    if(tile.tileType==kBottomRight)
    {
        spriteFileName=@"/images/dotgrid/tile-corner";
        [tile.mySprite setRotation:180.0f];
    }
    if(tile.tileType==kBorderLeft)
    {
        spriteFileName=@"/images/dotgrid/tile-border-single";
        [tile.mySprite setRotation:0.0f];
    }
    if(tile.tileType==kBorderRight)
    {
        spriteFileName=@"/images/dotgrid/tile-border-single";
        [tile.mySprite setRotation:180.0f];
    }
    if(tile.tileType==kBorderTop)
    {
        spriteFileName=@"/images/dotgrid/tile-border-single";
        [tile.mySprite setRotation:90.0f];
    }
    if(tile.tileType==kBorderBottom)
    {
        spriteFileName=@"/images/dotgrid/tile-border-single";
        [tile.mySprite setRotation:270.0f];
    }
    if(tile.tileType==kNoBorder)
    {
        spriteFileName=@"/images/dotgrid/tile-border-none";
    }
    
    tile.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@%d.png", spriteFileName, tile.tileSize]))];
    [tile.mySprite setPosition:tile.Position];
    
    // THE TINTING BEHAVIOUR HERE CAN ALSO BE APPLIED BY THE SHAPE TOUCH BEHAVIOUR    
    if(tile.Selected)[tile.mySprite setColor:ccc3(89,133,136)];
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [tile.mySprite setTag:2];
        [tile.mySprite setOpacity:0];
    }
    
    
    
    
    [[gameWorld Blackboard].ComponentRenderLayer addChild:tile.mySprite z:2];
    
    [spriteFileName release];
}

-(void)setSpritePos:(BOOL) withAnimation
{
    
    
}

-(void) dealloc
{
    [super dealloc];
}

@end
