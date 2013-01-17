//
//  BMountable.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueMountable.h"
#import "global.h"
#import "DWPlaceValueBlockGameObject.h"
#import "DWPlaceValueNetGameObject.h"
#import "DWPlaceValueCageGameObject.h"

@implementation BPlaceValueMountable

-(BPlaceValueMountable *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueMountable*)[super initWithGameObject:aGameObject withData:data];
    b=(DWPlaceValueBlockGameObject*)gameObject;
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMount)
    {

        if(b.Mount && !gameWorld.Blackboard.inProblemSetup && gameWorld.Blackboard.DropObject)
        {
            [b.Mount handleMessage:kDWunsetMountedObject];
            b.Mount=gameWorld.Blackboard.DropObject;
        }
        
        b.LastMount=b.Mount;
        
        DWPlaceValueCageGameObject *newMountC=nil;
        DWPlaceValueNetGameObject *newMountN=nil;
        
        if([b.Mount isKindOfClass:[DWPlaceValueNetGameObject class]])
        {
            newMountN=(DWPlaceValueNetGameObject*)b.Mount;
            newMountN.MountedObject=b;
        

            
            b.PosX=newMountN.PosX;
            b.PosY=newMountN.PosY;
        }
        else if([b.Mount isKindOfClass:[DWPlaceValueCageGameObject class]])
        {
            if(b.Selected)[b handleMessage:kDWswitchSelection];
            
            newMountC=(DWPlaceValueCageGameObject*)b.Mount;
        
            newMountC.MountedObject=b;
            
            
            b.PosX=newMountC.PosX;
            b.PosY=newMountC.PosY+20;
        }
        //tell the mount that i'm there

        
        b.AnimateMe=YES;

    
        //update the sprite
        //[gameObject handleMessage:kDWupdateSprite andPayload:[newMount store] withLogLevel:0];
        [gameObject handleMessage:kDWupdateSprite andPayload:nil withLogLevel:0];
        
        
    }
    
    if(messageType==kDWdismantle)
    {
        DWGameObject *m=b.Mount;
        if(m)
        {
            [m handleMessage:kDWunsetMountedObject];
        }
        b.Mount=nil;
    }
}

@end
