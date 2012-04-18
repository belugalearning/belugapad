//
//  BDotGridAnchorTouch.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDotGridAnchorTouch.h"
#import "DWDotGridAnchorGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"


@implementation BDotGridAnchorTouch

-(BDotGridAnchorTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDotGridAnchorTouch*)[super initWithGameObject:aGameObject withData:data];
    anch=(DWDotGridAnchorGameObject*)gameObject;
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
        [self checkTouch:loc];
    }
    
    if(messageType==kDWaddMeToSelection)
    {
        
    }
    
    if(messageType==kDWremoveMeFromSelection)
    {
        
    }
    
    if(messageType==kDWremoveAllFromSelection)
    {
        
    }
}

-(void)checkTouch:(CGPoint)hitLoc
{
    
    
    if([BLMath DistanceBetween:anch.Position and:hitLoc] <= (0.045f*[gameWorld Blackboard].hostLX))
    {
        //tell gameScene we are a target for that pickup
        
        if(anch.Disabled) {
            NSLog(@"got touched but i'm disabled pos x %d / y %d", anch.myXpos, anch.myYpos);  
        }
        else if(!anch.Disabled) {
            NSLog(@"got touched and i'm enabled! pos x %d / y %d", anch.myXpos, anch.myYpos);
            // we only want our first anchor to be set if there isn't one already.
            // this will be cleared on touchesended/cancelled
            
        }
        if(gameWorld.Blackboard.FirstAnchor==nil) gameWorld.Blackboard.FirstAnchor=anch;
        
        
        // but our last anchor always needs to be stored
        
        gameWorld.Blackboard.LastAnchor=anch;
        
        [anch handleMessage:kDWswitchSelection];
    }    
}

-(void) dealloc
{
    [super dealloc];
}

@end
