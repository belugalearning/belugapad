//
//  BFloatRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNBondObjectRender.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWNBondObjectGameObject.h"
#import "SimpleAudioEngine.h"

@implementation BNBondObjectRender

-(BNBondObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNBondObjectRender*)[super initWithGameObject:aGameObject withData:data];
    pogo = (DWNBondObjectGameObject*)gameObject;
    
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
    pogo.BaseNode = [[[CCNode alloc]init] autorelease];
    if(!pogo.Length) pogo.Length=1;
    
    NSString *spriteFileName=@"";
    //[[gameWorld GameSceneLayer] addChild:mySprite z:1];
    
    for(int i=0;i<pogo.Length+1;i++) {
        if(i==0)
        {
            if(pogo.HintObject)
                spriteFileName=@"/images/partition/block-l-hint.png";
            else
                spriteFileName=@"/images/partition/block-l.png";
            CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
            [mySprite setColor:kNumberBondColour[pogo.Length-1]];
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
            if(pogo.HintObject)
                spriteFileName=@"/images/partition/block-m-hint.png";
            else
                spriteFileName=@"/images/partition/block-m.png";
            CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
            [mySprite setColor:kNumberBondColour[pogo.Length-1]];
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
            if(pogo.HintObject)
                spriteFileName=@"/images/partition/block-r-hint.png";
            else
                spriteFileName=@"/images/partition/block-r.png";
            CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
            [mySprite setColor:kNumberBondColour[pogo.Length-1]];
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
        

        [pogo.Label setColor:ccc3(255,255,255)];
        
        [pogo.Label setPosition:ccp((pogo.Length * 50) * 0.5f, 0)];
        if(gameWorld.Blackboard.inProblemSetup){
            [pogo.Label setTag:2];
            [pogo.Label setOpacity:0];
        }
        [pogo.BaseNode addChild:pogo.Label z:10];
    }
    pogo.BaseNode.position=pogo.Position;
    [[gameWorld Blackboard].ComponentRenderLayer addChild:pogo.BaseNode z:2];
    
    [spriteFileName release];
    
}

-(void)setSpritePos:(BOOL) withAnimation
{
    if(!CGPointEqualToPoint(pogo.MovePosition, CGPointZero))
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
    pogo.BaseNode=nil;
    
    [super dealloc];
}

@end
