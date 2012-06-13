//
//  BFloatRender.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueObjectRender.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWPlaceValueBlockGameObject.h"
#import "DWPlaceValueCageGameObject.h"
#import "DWPlaceValueNetGameObject.h"

@implementation BPlaceValueObjectRender

-(BPlaceValueObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueObjectRender*)[super initWithGameObject:aGameObject withData:data];
    b=(DWPlaceValueBlockGameObject*)gameObject;
    
    //init pos x & y in case they're not set elsewhere
    b.PosX=0.0f;
    b.PosY=0.0f;
    
    amPickedUp=NO;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        CCSprite *mySprite=b.mySprite;
        if(!mySprite) 
        {
            [self setSprite];
            [self setSpritePosWithAnimation:NO];            
        }
    }
    
    if (messageType==kDWmoveSpriteToPosition) {
        BOOL useAnimation = b.AnimateMe;

        
        [self setSpritePosWithAnimation:useAnimation];
    }
    
    if(messageType==kDWupdateSprite)
    {
        
        if(b.Selected)
        { 
            [self switchSelection:b.Selected];
        }

        CCSprite *mySprite=b.mySprite;
        if(!mySprite) { 
            [self setSprite];
        }

        BOOL useAnimation = b.Selected;
        
        [self setSpritePosWithAnimation:useAnimation];
    }
        
    if(messageType==kDWpickedUp)
    {
        amPickedUp=YES;
    }
    
    if(messageType==kDWputdown)
    {
        amPickedUp=NO;
        
        CCSprite *mySprite=b.mySprite;
        if(b.PickupSprite && !gameWorld.Blackboard.inProblemSetup)
        {
            [mySprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(b.PickupSprite)]];

        }
    }
    
    if(messageType==kDWsetMount)
    {
        //does this need to be set?

    }
    if(messageType==kDWunsetMount)
    {
        //does this need to be unset?
    }
    if(messageType==kDWresetToMountPosition)
    {
        [self resetSpriteToMount];
    }
    if(messageType==kDWswitchBaseSelection)
    {
        [self switchBaseSelection:YES];
    }
    if(messageType==kDWswitchBaseSelectionBack)
    {
        [self switchBaseSelection:NO];        
    }
    if(messageType==kDWdismantle)
    {
        CCSprite *s=b.mySprite;
        [[s parent] removeChild:s cleanup:YES];
    }
}



-(void)setSprite
{
    NSString *spriteFileName=@"/images/placevalue/obj-placevalue-unit.png";
    //[[gameWorld GameSceneLayer] addChild:mySprite z:1];

    if(!b.SpriteFilename)
    {
        b.SpriteFilename=spriteFileName;
    }
    else {
        spriteFileName=b.SpriteFilename;
    }
    
    CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [mySprite setTag:2];
        [mySprite setOpacity:0];
    }
    if(b.ObjectValue<0)
    {
        [mySprite setColor:ccc3(255,0,0)];
    }
        [gameWorld.Blackboard.ComponentRenderLayer addChild:mySprite z:2];
    
    //keep a gos ref for sprite -- it's used for position lookups on child sprites (at least at the moment it is)
    b.mySprite=mySprite;
}

-(void)setSpritePosWithAnimation:(BOOL) animate
{

    CCSprite *mySprite=b.mySprite;
    
    float x=b.PosX;
    float y=b.PosY;
    
    
    
    if(animate == YES)
    {
        CGPoint newPos = ccp(x, y);

        CCMoveTo *anim = [CCMoveTo actionWithDuration:kTimeObjectSnapBack position:newPos];
        [mySprite runAction:anim];
    }
    else
    {
        [mySprite setPosition:ccp(x, y)];
    }

}

-(void)resetSpriteToMount
{
    DWPlaceValueCageGameObject *c=[DWPlaceValueCageGameObject alloc];
    DWPlaceValueNetGameObject *n=[DWPlaceValueNetGameObject alloc];
    
    float x;
    float y;
    
    if([b.Mount isKindOfClass:[DWPlaceValueCageGameObject class]])
    {
        c=(DWPlaceValueCageGameObject*)b.Mount;
        x=c.PosX;
        y=c.PosY;
    }
    else
    {
        n=(DWPlaceValueNetGameObject*)b.Mount;
        x=n.PosX;
        y=n.PosY;
    }
        
    

    b.PosX=x;
    b.PosY=y;
    
    
    CCSprite *curSprite = b.mySprite;
    
    if(b.SpriteFilename && !gameWorld.Blackboard.inProblemSetup)
    {
        NSString *spriteFileName=@"/images/placevalue/obj-placevalue-unit.png";
        if(b.SpriteFilename) spriteFileName=b.SpriteFilename;
        
        [curSprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(spriteFileName)]];
    }
    [curSprite runAction:[CCMoveTo actionWithDuration:kTimeObjectSnapBack position:ccp(x, y)]];
    
}

-(void) switchSelection:(BOOL)isSelected
{
    CCSprite *mySprite=b.mySprite;
    if(isSelected) {
        if(b.ObjectValue<0)
        {
            // if the object is a negative, what colour do we tint selection
            [mySprite setColor:ccc3(255,0,255)];
        }
        else {
            // tint for selection (+ number)
            [mySprite setColor:ccc3(255, 128, 0)]; 
        }
    }
    else
    {
        if(b.ObjectValue<0)
        {
            // default tint of a negative object
            [mySprite setColor:ccc3(255,0,0)];
        }
        else {
            // default tint of a positive number
            [mySprite setColor:ccc3(255, 255, 255)];
        }
    }
    
}
-(void) switchBaseSelection:(BOOL)isSelected
{
    CCSprite *mySprite=b.mySprite;
    if(isSelected)
    {
        if(b.ObjectValue<0)
        {
            // base selection tint of negative numbers
            [mySprite setColor:ccc3(255,0,105)];
        }
        else
        {
            // base selection tint of positive numbers
            [mySprite setColor:ccc3(255,255,0)]; 
        }
    }
    else
    {
        // Check whether selected
        if(b.Selected)
        {
            // then whether it's a +/- number
            if(b.ObjectValue<0)
            {
                //selection colour for a negative number
                [mySprite setColor:ccc3(255,0,255)];
            }
            else
            {
                [mySprite setColor:ccc3(255,128,0)];             
            }
        }
        else
        {
            if(b.ObjectValue<0)
            {
                [mySprite setColor:ccc3(255,0,105)];
            }
            else
            {
                [mySprite setColor:ccc3(255,255,255)];
        
            }
        }
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
