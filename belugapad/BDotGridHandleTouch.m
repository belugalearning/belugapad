//
//  BDotGridAnchorTouch.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDotGridHandleTouch.h"
#import "DWDotGridHandleGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"


@implementation BDotGridHandleTouch

-(BDotGridHandleTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDotGridHandleTouch*)[super initWithGameObject:aGameObject withData:data];
    handle=(DWDotGridHandleGameObject*)gameObject;
    //init pos x & y in case they're not set elsewhere
    
    
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWrenderSelection)
    {

    }
    if(messageType==kDWcanITouchYou)
    {
        CGPoint loc=[[payload objectForKey:POS] CGPointValue];
        [self setCurrentHandle:loc];
    }
    if(messageType==kDWuseThisHandle)
    {
        if(handle.handleType==kMoveHandle) [handle.myShape handleMessage:kDWmoveShape andPayload:payload withLogLevel:-1];
        if(handle.handleType==kResizeHandle) [handle.myShape handleMessage:kDWresizeShape andPayload:payload withLogLevel:-1];
    }
}

-(void)setCurrentHandle:(CGPoint)hitLoc
{
    hitLoc=[handle.RenderLayer convertToNodeSpace:hitLoc];
    if([BLMath DistanceBetween:handle.Position and:hitLoc] <= (0.03f*[gameWorld Blackboard].hostLX))
    {
        //NSLog(@"touch handle of type %d", handle.handleType);
        if(handle.handleType=kResizeHandle) gameWorld.Blackboard.CurrentHandle=handle;
        else NSLog(@"this handle isn't valid.");
    }
}

-(void)resizeShape:(CGPoint)hitLoc
{
    
}

-(void)moveShape:(CGPoint)hitLoc
{
    
}


-(void) dealloc
{
    [super dealloc];
}

@end
