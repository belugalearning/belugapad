//
//  BFloatPickupTarget.m
//  belugapad
//
//  Created by Gareth Jenkins on 07/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BFloatPickupTarget.h"
#import "BLMath.h"
#import "global.h"

static float kProximateHalfSizeDist=4.5f;

@implementation BFloatPickupTarget

-(BFloatPickupTarget *)initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BFloatPickupTarget *)[super initWithGameObject:aGameObject withData:data];
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    
    if(messageType==kDWareYouAPickupTarget)
    {        
        //get coords from payload (i.e. the search target)
        float xhit=[[payload objectForKey:POS_X] floatValue];
        float yhit=[[payload objectForKey:POS_Y] floatValue];
        CGPoint hitLoc=ccp(xhit, yhit);
        
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        NSMutableArray *spriteTest=[self lookupSprites];
        
        for (CCSprite *s in spriteTest) {
            CGPoint p;
            if(s==mySprite)
                p=[mySprite position];
            else
                p=[mySprite convertToWorldSpace:[s position]];
            
            
            if([BLMath DistanceBetween:p and:hitLoc]<=(HALF_SIZE*1.5f))
            {
                //game scene will pickup object from here
                [gameWorld Blackboard].PickupObject=gameObject;
                
                //will be 0,0 if primary sprite was pickup
                [gameWorld Blackboard].PickupOffset=[BLMath SubtractVector:[mySprite position] from:p];
                
                break;
            }
        }
    }
    
    if(messageType==kDWareYouProximateTo)
    {
        //very similar to areYouAPickupTarget -- could likely merge to single parameterised lookup if suitable 
        //likey not though, this needs to evaluate object-object
        //get coords from payload (i.e. the search target)
        DWGameObject *tgo=[payload objectForKey:TARGET_GO];
        
        //not interested in proximity to self
        if(tgo==gameObject) return;
        
        float xhit=[[[tgo store] objectForKey:POS_X] floatValue];
        float yhit=[[[tgo store] objectForKey:POS_Y] floatValue];
        CGPoint hitLoc=ccp(xhit, yhit);
        
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        
        for(NSDictionary *dc in [[gameObject store] objectForKey:OBJ_CHILDMATRIX])
        {
            CCSprite *s=[dc objectForKey:MY_SPRITE];
            CGPoint p;
            if(s==mySprite)
                p=[mySprite position];
            else
                p=[mySprite convertToWorldSpace:[s position]];
            
            
            if([BLMath DistanceBetween:p and:hitLoc]<=(HALF_SIZE*kProximateHalfSizeDist))
            {
                [gameWorld Blackboard].ProximateObject=gameObject;
                
                break;
            }
        }
    }
    
    if(messageType==kDWsetMount)
    {
        GOS_SET([payload objectForKey:MOUNT], MOUNT);
    }
    
    if(messageType==kDWunsetMount)
    {
        [[gameObject store] removeObjectForKey:MOUNT];
    }
}

-(NSMutableArray *)lookupSprites
{
    //bulid array of all sprites to test -- this is master + children
    CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
    NSMutableArray *spriteTest=[NSMutableArray arrayWithArray:[[mySprite children] getNSArray]];
    [spriteTest addObject:mySprite];

    return spriteTest;
}



@end
