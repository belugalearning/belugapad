//
//  BMount.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueMountCage.h"
#import "global.h"
#import "SimpleAudioEngine.h"
#import "PlaceValue.h"
#import "DWPlaceValueNetGameObject.h"
#import "DWPlaceValueCageGameObject.h"
#import "DWPlaceValueBlockGameObject.h"

@implementation BPlaceValueMountCage

-(BPlaceValueMountCage *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueMountCage*)[super initWithGameObject:aGameObject withData:data];
    
    c=(DWPlaceValueCageGameObject*)gameObject;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMountedObject)
    {
        //set the mount for the GO
        evalLeft = NO;
        evalUp = NO;

        [[gameWorld GameScene] problemStateChanged];
        
        if(c.AllowMultipleMount)
            [c handleMessage:kDWdeselectAll];
    }
    
    if(messageType==kDWunsetMountedObject)
    {
        
    }
    if(messageType==kDWresetPositionEval)
    {
        evalLeft=NO;
        evalUp=NO;
    }
}

@end
