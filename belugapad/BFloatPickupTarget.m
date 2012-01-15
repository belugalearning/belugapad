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
        
        //tofu: currently using fixed proximity -- this will need to change for non-square shapes (maybe with hit test on shape or similar)
        
        //bulid array of all sprites to test -- this is master + children
        CCSprite *mySprite=[[gameObject store] objectForKey:MY_SPRITE];
        NSMutableArray *spriteTest=[NSMutableArray arrayWithArray:[[mySprite children] getNSArray]];
        [spriteTest addObject:mySprite];
        
        for (CCSprite *s in spriteTest) {
            CGPoint p;
            if(s==mySprite)
                p=[mySprite position];
            else
                p=[mySprite convertToWorldSpace:[s position]];
            
            
            if([BLMath DistanceBetween:p and:hitLoc]<=HALF_SIZE)
            {
                //game scene will pickup object from here
                [gameWorld Blackboard].PickupObject=gameObject;
                
                //will be 0,0 if primary sprite was pickup
                [gameWorld Blackboard].PickupOffset=[BLMath SubtractVector:[mySprite position] from:p];
                
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

@end
