//
//  BFloatRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPartitionObjectRender.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWPartitionObjectGameObject.h"

@implementation BPartitionObjectRender

-(BPartitionObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPartitionObjectRender*)[super initWithGameObject:aGameObject withData:data];
    pogo = (DWPartitionObjectGameObject*)gameObject;
    
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
            [self setSpritePos:NO];            
        }
    }
    
    if (messageType==kDWmoveSpriteToPosition) {
        BOOL useAnimation = NO;
        if([payload objectForKey:ANIMATE_ME]) useAnimation = YES;
        
        [self setSpritePos:useAnimation];
    }
    if(messageType==kDWmoveSpriteToHome)
    {
        [self moveSpriteHome];
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
        
    if(messageType==kDWpickedUp)
    {
        amPickedUp=YES;
    }
    
    if(messageType==kDWputdown)
    {
        amPickedUp=NO;
    }
    
    if(messageType==kDWresetToMountPosition)
    {
        [self resetSpriteToMount];
    }
    if(messageType==kDWdismantle)
    {
        CCSprite *s=[[gameObject store] objectForKey:MY_SPRITE];
        [[s parent] removeChild:s cleanup:YES];
    }
}



-(void)setSprite
{
    NSMutableArray *mySprites=[[NSMutableArray alloc]init];
    if(!pogo.Length) pogo.Length=1;
    
    NSString *spriteFileName=[[NSString alloc]init];
    //[[gameWorld GameSceneLayer] addChild:mySprite z:1];
    
    for(int i=0;i<pogo.Length;i++) {
        if(i==0)
        {
            spriteFileName=@"/images/partition/block-l.png";
            CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
            float thisXPos = pogo.Position.x-13;
            [mySprite setPosition:ccp(thisXPos, pogo.Position.y)];
            [gameWorld.Blackboard.ComponentRenderLayer addChild:mySprite z:2];
            [mySprites addObject:mySprite];
            if(gameWorld.Blackboard.inProblemSetup)
            {
                [mySprite setTag:2];
                [mySprite setOpacity:0];
            }

        }
        spriteFileName=@"/images/partition/block-m.png";
        NSLog(@"pogo position x %f", pogo.Position.x);
        CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
        float thisXPos = pogo.Position.x+(i*25);
        [mySprite setPosition:ccp(thisXPos, pogo.Position.y)];
        NSLog(@"thisXPos position x %f", thisXPos);

        
        if(gameWorld.Blackboard.inProblemSetup)
        {
            [mySprite setTag:2];
            [mySprite setOpacity:0];
        }
        [gameWorld.Blackboard.ComponentRenderLayer addChild:mySprite z:2];
        if(i==pogo.Length-1)
        {
            spriteFileName=@"/images/partition/block-r.png";
            CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
            float thisXPos = pogo.Position.x+(i*25)+13;
            [mySprite setPosition:ccp(thisXPos, pogo.Position.y)];
            [gameWorld.Blackboard.ComponentRenderLayer addChild:mySprite z:2];
            [mySprites addObject:mySprite];
            if(gameWorld.Blackboard.inProblemSetup)
            {
                [mySprite setTag:2];
                [mySprite setOpacity:0];
            }
            
        }
        //keep a gos ref for sprite -- it's used for position lookups on child sprites (at least at the moment it is)
        [mySprites addObject:mySprite];
        [[gameObject store] setObject:mySprites forKey:MY_SPRITE];
    }
    
}

-(void)setSpritePos:(BOOL) withAnimation
{
    
    if(pogo.MovePosition.x || pogo.MovePosition.y)
    {
        NSMutableArray *mySprites=[[gameObject store] objectForKey:MY_SPRITE];
        
        for(int i=0; i<mySprites.count; i++)
        {
            CCSprite *curSprite = [mySprites objectAtIndex:i];
            if(withAnimation == YES)
            {
                CGPoint newPos = ccp(pogo.MovePosition.x, pogo.MovePosition.y);

                CCMoveTo *anim = [CCMoveTo actionWithDuration:kTimeObjectSnapBack position:newPos];
                [curSprite runAction:anim];
            }
            else
            {
                [curSprite setPosition:ccp(pogo.MovePosition.x+(i*25), pogo.MovePosition.y)];
            }
        }
    }
}
-(void)moveSpriteHome
{
    NSMutableArray *mySprites=[[gameObject store] objectForKey:MY_SPRITE];
    for(int i=0; i<mySprites.count; i++)
    {
        CCSprite *curSprite = [mySprites objectAtIndex:i];
        CCMoveTo *anim = [CCMoveTo actionWithDuration:kTimeObjectSnapBack position:ccp(pogo.Position.x+(i*25), pogo.Position.y)];
        [curSprite runAction:anim];
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

-(void) dealloc
{
    [super dealloc];
}

@end
