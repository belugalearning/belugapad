//
//  BNLineSelectorInput.m
//  belugapad
//
//  Created by David Amphlett on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BNLineSelectorInput.h"
#import "BLMath.h"
#import "global.h"
#import "DWSelectorGameObject.h"
#import "NLineConsts.h"

@implementation BNLineSelectorInput

-(BNLineSelectorInput *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BNLineSelectorInput*)[super initWithGameObject:aGameObject withData:data];
    selector=(DWSelectorGameObject*)gameObject;
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    
    if(messageType==kDWsetupStuff)
    {
        
    }
    if(messageType==kDWhandleTap)
    {
        CGPoint loc=[[payload objectForKey:POS] CGPointValue];

        if([BLMath DistanceBetween:selector.pos and:loc] < kSelectorProximity)
        {
            // if the tap is on the selector - do stuff
        }
    }
}

-(void)doUpdate:(ccTime)delta
{
    
    
}


@end
