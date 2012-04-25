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
    pogo.BaseNode = [[CCNode alloc]init];
    NSMutableArray *mySprites=[[NSMutableArray alloc]init];
    if(!pogo.Length) pogo.Length=1;
    
    NSString *spriteFileName=[[NSString alloc]init];
    //[[gameWorld GameSceneLayer] addChild:mySprite z:1];
    
    for(int i=0;i<pogo.Length+1;i++) {
        if(i==0)
        {
            spriteFileName=@"/images/partition/block-l.png";
            CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
            float thisXPos = 0;
            [mySprite setPosition:ccp(thisXPos, 0)];
            [pogo.BaseNode addChild:mySprite z:2];
            [mySprites addObject:mySprite];
            if(gameWorld.Blackboard.inProblemSetup)
            {
                [mySprite setTag:2];
                [mySprite setOpacity:0];
            }

        }
        
        if(i !=0 && i !=pogo.Length)
        {
            spriteFileName=@"/images/partition/block-m.png";
            NSLog(@"pogo position x %f", pogo.Position.x);
            CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
            float thisXPos = i*50;
            [mySprite setPosition:ccp(thisXPos, 0)];

            
            if(gameWorld.Blackboard.inProblemSetup)
            {
                [mySprite setTag:2];
                [mySprite setOpacity:0];
            }
            [pogo.BaseNode addChild:mySprite z:2];
        }
        
        if(i==pogo.Length)
        {
            spriteFileName=@"/images/partition/block-r.png";
            CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
            float thisXPos = i*50;
            [mySprite setPosition:ccp(thisXPos, 0)];
            [pogo.BaseNode addChild:mySprite z:2];
            [mySprites addObject:mySprite];
            if(gameWorld.Blackboard.inProblemSetup)
            {
                [mySprite setTag:2];
                [mySprite setOpacity:0];
            }
            
        }
        
        //keep a gos ref for sprite -- it's used for position lookups on child sprites (at least at the moment it is)
        //[mySprites addObject:mySprite];
        //[[gameObject store] setObject:mySprites forKey:MY_SPRITE];
    }
    
    if(pogo.Label) { 
        [pogo.Label setColor:ccc3(0,0,0)];
        [pogo.Label setPosition:ccp((pogo.Length * 50) * 0.5f, 0)];
        [pogo.Label setTag:2];
        [pogo.Label setOpacity:0];
        [pogo.BaseNode addChild:pogo.Label z:10];
    }
    pogo.BaseNode.position=pogo.Position;
    [[gameWorld Blackboard].ComponentRenderLayer addChild:pogo.BaseNode z:2];
    
}

-(void)setSpritePos:(BOOL) withAnimation
{
    
    if(pogo.MovePosition.x || pogo.MovePosition.y)
    {
        
            if(withAnimation == YES)
            {
                pogo.BaseNode.position=pogo.MovePosition;

                CCMoveTo *anim = [CCMoveTo actionWithDuration:kTimeObjectSnapBack position:pogo.MovePosition];
                [pogo.BaseNode runAction:[CCEaseIn actionWithAction:anim rate:0.5f]];
            }
            else
            {
                [pogo.BaseNode setPosition:pogo.MovePosition];
                
            }
    }
}
-(void)moveSpriteHome
{
    CCMoveTo *anim = [CCMoveTo actionWithDuration:kTimeObjectSnapBack position:pogo.MountPosition];
    [pogo.BaseNode runAction:[CCEaseIn actionWithAction:anim rate:0.5f]];
    pogo.Position=pogo.MountPosition;
    [pogo handleMessage:kDWunsetMount];
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
