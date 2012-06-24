//
//  BFloatPickupTarget.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPartitionPickupTarget.h"
#import "BLMath.h"
#import "global.h"
#import "DWPartitionObjectGameObject.h"
#import "DWPartitionRowGameObject.h"
#import "AppDelegate.h"
#import "LoggingService.h"

@interface BPartitionPickupTarget()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
}
@end

@implementation BPartitionPickupTarget

-(BPartitionPickupTarget *)initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    loggingService = ac.loggingService;
    contentService = ac.contentService;
    
    self=(BPartitionPickupTarget *)[super initWithGameObject:aGameObject withData:data];
    pogo=(DWPartitionObjectGameObject*)gameObject;
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouAPickupTarget)
    {   
        CGRect boundingBox = CGRectZero;
        for(int i=0;i<pogo.BaseNode.children.count;i++)
        {
            CCSprite *curSprite = [pogo.BaseNode.children objectAtIndex:i];
            boundingBox=CGRectUnion(boundingBox, curSprite.boundingBox);
        }
        //get coords from payload (i.e. the search target)
        float xhit=[[payload objectForKey:POS_X] floatValue];
        float yhit=[[payload objectForKey:POS_Y] floatValue];
        
        CGPoint hitLoc=ccp(xhit, yhit);
        
        if(CGRectContainsPoint(boundingBox, [pogo.BaseNode convertToNodeSpace:hitLoc]) && !pogo.Mount.Locked)
        {
            //tell gameScene we are a target for that pickup
            [gameWorld Blackboard].PickupObject=gameObject;
        } 
        else if(CGRectContainsPoint(boundingBox, [pogo.BaseNode convertToNodeSpace:hitLoc]) && pogo.Mount.Locked)
        {
            [loggingService logEvent:BL_PA_NB_TOUCH_BEGIN_ON_LOCKED_ROW withAdditionalData:nil];
        }
    }
}

@end
