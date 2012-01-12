//
//  BDropTarget.m
//  belugapad
//
//  Created by Gareth Jenkins on 04/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDropTarget.h"
#import "global.h"
#import "BLMath.h"

@implementation BDropTarget

-(BDropTarget *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDropTarget*)[super initWithGameObject:aGameObject withData:data];
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouADropTarget)
    {
        //only check if I'm not currently mounting something else
        if([[gameObject store] objectForKey:MOUNTED_OBJECT]==nil)
        {
            //get current loc
            float x=[[[gameObject store] objectForKey:POS_X] floatValue];
            float y=[[[gameObject store] objectForKey:POS_Y] floatValue];   
            CGPoint myLoc=ccp(x,y);
            
            //get coords from payload (i.e. the search target)
            float xhit=[[payload objectForKey:POS_X] floatValue];
            float yhit=[[payload objectForKey:POS_Y] floatValue];
            CGPoint hitLoc=ccp(xhit, yhit);
            
            //look see if this is close enough
            if([BLMath DistanceBetween:myLoc and:hitLoc] <= DROP_PROXIMITY)
            {
                //tell gameScene we are a target for that pickup
                [gameWorld Blackboard].DropObject=gameObject;
                

            }
        }

    }
}

@end
