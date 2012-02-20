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

@implementation BPlaceValueObjectRender

-(BPlaceValueObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    amPickedUp=NO;
    
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
            [self setSpritePos:[gameObject store] withAnimation:NO];            
        }
    }
    
    if(messageType==kDWupdateSprite)
    {
        NSNumber *isSelected = [[gameObject store] objectForKey:SELECTED];
        
        if(!isSelected)
        { 
        }
        else
        {
            [self switchSelection:[isSelected boolValue]];
        }

        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        if(!mySprite) { 
            [self setSprite];
        }

        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
        [self setSpritePos:payload withAnimation:useAnimation];
    }
        
    if(messageType==kDWpickedUp)
    {
        amPickedUp=YES;
    }
    
    if(messageType==kDWputdown)
    {
        amPickedUp=NO;
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
        CCSprite *s=[[gameObject store] objectForKey:MY_SPRITE];
        [[s parent] removeChild:s cleanup:YES];
    }
}



-(void)setSprite
{
    NSString *spriteFileName=@"obj-placevalue-unit.png";
    //[[gameWorld GameSceneLayer] addChild:mySprite z:1];

    if([[gameObject store] objectForKey:SPRITE_FILENAME])
    {
        spriteFileName=[[gameObject store] objectForKey:SPRITE_FILENAME];
    }
    
        CCSprite *mySprite=[CCSprite spriteWithFile:spriteFileName];
        [gameWorld.Blackboard.ComponentRenderLayer addChild:mySprite z:1];
    
    //keep a gos ref for sprite -- it's used for position lookups on child sprites (at least at the moment it is)
    [[gameObject store] setObject:mySprite forKey:MY_SPRITE];
}

-(void)setSpritePos:(NSDictionary *)position withAnimation:(BOOL) animate
{
    if(position != nil)
    {
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        
        float x=[[position objectForKey:POS_X] floatValue];
        float y=[[position objectForKey:POS_Y] floatValue];
        
        
        //also set posx/y on store
        GOS_SET([NSNumber numberWithFloat:x], POS_X);
        GOS_SET([NSNumber numberWithFloat:y], POS_Y);
        
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
}

-(void)resetSpriteToMount
{
    DWGameObject *mount = [[gameObject store] objectForKey:MOUNT];
    float x = [[[mount store] objectForKey:POS_X] floatValue];
    float y = [[[mount store] objectForKey:POS_Y] floatValue];
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:x] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:y] forKey:POS_Y];
    
    CCSprite *curSprite = [[gameObject store] objectForKey:MY_SPRITE];
    
    [curSprite runAction:[CCMoveTo actionWithDuration:kTimeObjectSnapBack position:ccp(x, y)]];
    
}

-(void) switchSelection:(BOOL)isSelected
{
    CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
    if(isSelected) {
        [mySprite setColor:ccc3(0, 255, 0)]; 
    }
    else
    {
        [mySprite setColor:ccc3(255, 255, 255)];
    }
    
}
-(void) switchBaseSelection:(BOOL)isSelected
{
    CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
    if(isSelected)
    {

        [mySprite setColor:ccc3(255, 255, 0)]; 
    }
    else
    {
        if([[gameObject store] objectForKey:SELECTED])
        {
            [mySprite setColor:ccc3(0, 255, 0)];             
        }
        else
        {
            [mySprite setColor:ccc3(255, 255, 255)];
        }
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
