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
//        //set the old mount
//        if(b.Mount)
//            [b.Mount handleMessage:kDWunsetMountedObject];
//            
//        //set the new mount for the GO
        DWPlaceValueNetGameObject *newMount=(DWPlaceValueNetGameObject*)b.Mount;
//        b.Mount=newMount;
        
        //tell the mount that i'm there
        newMount.MountedObject=b;
        
        
        b.PosX=newMount.PosX;
        b.PosY=newMount.PosY; 
        
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
