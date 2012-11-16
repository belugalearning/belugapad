//
//  BFloatPickupTarget.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNBondPickupTarget.h"
#import "BLMath.h"
#import "global.h"
#import "DWNBondObjectGameObject.h"
#import "DWNBondRowGameObject.h"
#import "AppDelegate.h"
#import "LoggingService.h"

@interface BNBondPickupTarget()
{
@private
    LoggingService *loggingService;
    ContentService *contentService;
}
@end

@implementation BNBondPickupTarget

-(BNBondPickupTarget *)initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    loggingService = ac.loggingService;
    contentService = ac.contentService;
    
    self=(BNBondPickupTarget *)[super initWithGameObject:aGameObject withData:data];
    pogo=(DWNBondObjectGameObject*)gameObject;
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWareYouAPickupTarget)
    {
        if(pogo.HintObject)return;
        if(pogo.InitedObject)return;
        
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
