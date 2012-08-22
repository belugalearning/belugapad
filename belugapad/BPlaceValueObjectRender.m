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
#import "InteractionFeedback.h"

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
            [self setSpritePosWithAnimation];            
        }
    }
    
    if (messageType==kDWmoveSpriteToPosition) {
        
        [b.mySprite stopAllActions];
        
        b.AnimateMe=YES;
        [self setSpritePosWithAnimation];
    }
    
    if(messageType==kDWmoveSpriteToPositionWithoutAnimation){
        [b.mySprite stopAllActions];
        
        b.AnimateMe=NO;
        [self setSpritePosWithAnimation];
    }
    
    if(messageType==kDWupdateSprite)
    {
        

        [self switchSelection:b.Selected];

        CCSprite *mySprite=b.mySprite;
        if(!mySprite) { 
            [self setSprite];
        }


        
        [self setSpritePosWithAnimation];
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
    
    if(messageType==kDWcheckMyMountIsCage)
    {
        if([b.Mount isKindOfClass:[DWPlaceValueCageGameObject class]])
            [b.mySprite runAction:[InteractionFeedback shakeAction]];
    }
    if(messageType==kDWcheckMyMountIsNet)
    {
        if([b.Mount isKindOfClass:[DWPlaceValueNetGameObject class]])
            [b.mySprite runAction:[InteractionFeedback shakeAction]];
    }
    
    if(messageType==kDWstopAllActions)
    {
        [b.mySprite stopAllActions];
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
    if(messageType==kDWresetToMountPositionAndDestroy)
    {
        [self resetSpriteToMountAndDestroy];
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
        [gameWorld.Blackboard.ComponentRenderLayer addChild:mySprite z:50];
    
    //keep a gos ref for sprite -- it's used for position lookups on child sprites (at least at the moment it is)
    b.mySprite=mySprite;
}

-(void)setSpritePosWithAnimation
{

    CCSprite *mySprite=b.mySprite;
    
    if(b.AnimateMe)
    {
        CGPoint newPos = ccp(b.PosX,b.PosY);

        CCMoveTo *anim = [CCMoveTo actionWithDuration:kTimeObjectSnapBack position:newPos];
        [mySprite runAction:anim];
        b.AnimateMe=NO;
    }
    else
    {
        [mySprite setPosition:ccp(b.PosX,b.PosY)];
    }

    
}

-(void)resetSpriteToMount
{
    DWPlaceValueCageGameObject *c;
    DWPlaceValueNetGameObject *n;
    
    float x;
    float y;
    
    if([b.Mount isKindOfClass:[DWPlaceValueCageGameObject class]])
    {
        c=(DWPlaceValueCageGameObject*)b.Mount;
        x=c.PosX;
        y=c.PosY;
    }
    else if([b.Mount isKindOfClass:[DWPlaceValueNetGameObject class]])
    {
        n=(DWPlaceValueNetGameObject*)b.Mount;
        x=n.PosX;
        y=n.PosY;
//        gameObject=n.MountedObject;
        //[n handleMessage:kDWresetPositionEval];
    }
        
    

    b.PosX=x;
    b.PosY=y;
    
    CGPoint moveLoc=ccp(b.PosX, b.PosY);
    
    CCSprite *curSprite = b.mySprite;
    
    if(b.SpriteFilename && !gameWorld.Blackboard.inProblemSetup)
    {
        NSString *spriteFileName=@"/images/placevalue/obj-placevalue-unit.png";
        if(b.SpriteFilename) spriteFileName=b.SpriteFilename;
        
        [curSprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(spriteFileName)]];
    }
    [curSprite runAction:[CCMoveTo actionWithDuration:kTimeObjectSnapBack position:moveLoc]];
    
}

-(void)resetSpriteToMountAndDestroy
{
    DWPlaceValueCageGameObject *c;
    
    if([b.Mount isKindOfClass:[DWPlaceValueCageGameObject class]])
    {
        c=(DWPlaceValueCageGameObject*)b.Mount;
        b.PosX=c.PosX;
        b.PosY=c.PosY;
    }
    
    CCSprite *curSprite = b.mySprite;
    
    if(b.SpriteFilename && !gameWorld.Blackboard.inProblemSetup)
    {
        NSString *spriteFileName=@"/images/placevalue/obj-placevalue-unit.png";
        if(b.SpriteFilename) spriteFileName=b.SpriteFilename;
        
        [curSprite setTexture:[[CCTextureCache sharedTextureCache] addImage: BUNDLE_FULL_PATH(spriteFileName)]];
    }
    
    CCMoveTo *moveAct=[CCMoveTo actionWithDuration:kTimeObjectSnapBack position:ccp(b.PosX, b.PosY)];
    CCAction *cleanUpSprite=[CCCallBlock actionWithBlock:^{[curSprite removeFromParentAndCleanup:YES];}];
    CCAction *cleanUpGO=[CCCallBlock actionWithBlock:^{[gameWorld delayRemoveGameObject:b];}];
    CCSequence *sequence=[CCSequence actions:moveAct, cleanUpSprite, cleanUpGO, nil];
    [curSprite runAction:sequence];
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
            [mySprite setColor:ccc3(128, 195, 194)];
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
                [mySprite setColor:ccc3(128, 195, 194)];
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
