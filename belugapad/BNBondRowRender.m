//
//  BFloatRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNBondRowRender.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWNBondRowGameObject.h"

@implementation BNBondRowRender

-(BNBondRowRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNBondRowRender*)[super initWithGameObject:aGameObject withData:data];
    pogo = (DWNBondRowGameObject*)gameObject;
    
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
    
    if(messageType==kDWhighlight)
    {
        for(CCSprite *s in pogo.BaseNode.children)
        {
            [s setColor:ccc3(255,255,255)];
        }
    }
}



-(void)setSprite
{
    pogo.BaseNode = [[[CCNode alloc]init] autorelease];
    NSString *spriteFileName=@"";
    int lengthWithStops=pogo.Length+2;
    
//    float xPos=0;
    
    for(int i=0;i<lengthWithStops;i++)
    {
    
        if(i==0)spriteFileName=@"/images/partition/NB_Grid_Solid_End_Left.png";
        else if(i==lengthWithStops-1 && pogo.Locked)spriteFileName=@"/images/partition/NB_Grid_Solid_End_Right.png";
        else if(i==lengthWithStops-1 && !pogo.Locked)spriteFileName=@"/images/partition/NB_Grid_Open_End_Right.png";
        else spriteFileName=@"/images/partition/NB_Grid_Middle50.png";
        
        
        CCSprite *mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
        [mySprite setPosition:ccp((i*50)-25,0)];

//        [mySprite setPosition:ccp(xPos,0)];
            
        
//        if(i==0)
//            xPos+=32;
//            
//        else if(i==lengthWithStops-2 && pogo.Locked)
//            xPos+=34;
//        
//        else if(i==lengthWithStops-2 && !pogo.Locked)
//            xPos+=42;
//        
//        else
//            xPos+=50;
        
            if(gameWorld.Blackboard.inProblemSetup)
            {
                [mySprite setTag:1];
                [mySprite setOpacity:0];
            }

            [pogo.BaseNode addChild:mySprite z:2];

    }
    pogo.BaseNode.position = pogo.Position;
    [[gameWorld Blackboard].ComponentRenderLayer addChild:pogo.BaseNode z:2];
    
    [spriteFileName release];
}

-(void)setSpritePos:(BOOL) withAnimation
{
    
    if(pogo.Position.x || pogo.Position.y)
    {
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        

        
          if(withAnimation == YES)
        {
            CGPoint newPos = ccp(pogo.Position.x, pogo.Position.y);

            CCMoveTo *anim = [CCMoveTo actionWithDuration:kTimeObjectSnapBack position:newPos];
            [mySprite runAction:anim];
        }
        else
        {
            [mySprite setPosition:pogo.Position];
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

-(void) dealloc
{
    pogo.BaseNode=nil;
    
    [super dealloc];
}

@end
