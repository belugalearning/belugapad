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
        if(!pogo.BaseNode) 
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

        if(!pogo.BaseNode) { 
            [self setSprite];
        }

        BOOL useAnimation = NO;
        
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
    if(messageType==kDWstopAllActions)
    {
        [pogo.BaseNode stopAllActions];
        [self resetSpriteToMount];
    }
    if(messageType==kDWdismantle)
    {
        CCNode *b=pogo.BaseNode;
        [[b parent] removeChild:pogo.BaseNode cleanup:YES];
    }
}



-(void)setSprite
{
    pogo.BaseNode = [[CCNode alloc]init];
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
            if(gameWorld.Blackboard.inProblemSetup)
            {
                [mySprite setTag:2];
                [mySprite setOpacity:0];
            }

        }
        
        if(i !=0 && i !=pogo.Length)
        {
            spriteFileName=@"/images/partition/block-m.png";
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
            if(gameWorld.Blackboard.inProblemSetup)
            {
                [mySprite setTag:2];
                [mySprite setOpacity:0];
            }
            
        }
        
    }
    
    if(pogo.InitedObject || pogo.IsScaled){
        [pogo.BaseNode setScale:1.0f];
        pogo.IsScaled=YES;
    }
    else{ 
        [pogo.BaseNode setScale:0.5f];
    }
    
    if(pogo.Label) { 
        [pogo.Label setColor:ccc3(0,0,0)];
        [pogo.Label setPosition:ccp((pogo.Length * 50) * 0.5f, -3)];
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
        if(!pogo.IsScaled)
        {
            [pogo.BaseNode runAction:[CCScaleTo actionWithDuration:0.5f scale:1.0f]];
            pogo.IsScaled=YES;
        }
        
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
    if(!pogo.NoScaleBlock)[self resetHalfScale];
    
}
-(void)resetSpriteToMount
{

    
}

-(void)resetHalfScale
{
    if(pogo.IsScaled && !pogo.InitedObject)
    {
        [pogo.BaseNode runAction:[CCScaleTo actionWithDuration:0.5f scale:0.5f]];
        pogo.IsScaled=NO;
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
