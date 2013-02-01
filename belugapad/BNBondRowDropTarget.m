//
//  BPlaceValueDropTarget.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNBondRowDropTarget.h"
#import "DWNBondRowGameObject.h"
#import "global.h"
#import "BLMath.h"
#import "DWNBondObjectGameObject.h"

@implementation BNBondRowDropTarget

-(BNBondRowDropTarget *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNBondRowDropTarget*)[super initWithGameObject:aGameObject withData:data];
    prgo = (DWNBondRowGameObject*)gameObject;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouADropTarget)
    {

        //get current loc
        //CGPoint myLoc=prgo.Position;
        //myLoc = [gameWorld.Blackboard.ComponentRenderLayer convertToNodeSpace:myLoc];
        
        
        //get coords from payload (i.e. the search target)
        float xhit=[[payload objectForKey:POS_X] floatValue];
        float yhit=[[payload objectForKey:POS_Y] floatValue];
        CGPoint hitLoc=ccp(xhit, yhit);
        
        CGRect boundingBox = CGRectZero;
        for(int i=0;i<prgo.BaseNode.children.count;i++)
        {
            CCSprite *curSprite = [prgo.BaseNode.children objectAtIndex:i];
            boundingBox=CGRectUnion(boundingBox, curSprite.boundingBox);
        }
        
        CGRect newBndBox=CGRectMake(boundingBox.origin.x, boundingBox.origin.y-30, boundingBox.size.width, boundingBox.size.height+60);

        
        if(CGRectContainsPoint(newBndBox, [prgo.BaseNode convertToNodeSpace:hitLoc]) && !prgo.Locked)
            {
                float myHeldValue=0.0f;
                for(int i=0;i<prgo.MountedObjects.count;i++)
                {
                    DWNBondObjectGameObject *mo = [prgo.MountedObjects objectAtIndex:i];
                    myHeldValue=myHeldValue+mo.Length;
                }
                DWNBondObjectGameObject *newO = (DWNBondObjectGameObject*)gameWorld.Blackboard.PickupObject;
                if(myHeldValue+newO.Length<=prgo.Length)
                {           
                    // change the hover-over tint colour
                    for(CCSprite *s in prgo.BaseNode.children)
                    {
                        [s setColor:ccc3(0,255,0)];
                    }
                    gameWorld.Blackboard.DropObject=gameObject;
                    
                }
                else
                {
                    gameWorld.Blackboard.ProximateObject=gameObject;
                }

            }
        else {
            // if not a valid droptarget, not in view, set all sprites back to their proper colour
            for(CCSprite *s in prgo.BaseNode.children)
            {
                [s setColor:ccc3(255,255,255)];
            }
        }

    }
}

@end
