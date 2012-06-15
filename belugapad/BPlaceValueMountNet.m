//
//  BMount.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueMountNet.h"
#import "global.h"
#import "SimpleAudioEngine.h"
#import "PlaceValue.h"
#import "DWPlaceValueNetGameObject.h"
#import "DWPlaceValueCageGameObject.h"
#import "DWPlaceValueBlockGameObject.h"

@implementation BPlaceValueMountNet

-(BPlaceValueMountNet *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueMountNet*)[super initWithGameObject:aGameObject withData:data];
    
    n=(DWPlaceValueNetGameObject*)gameObject;
    
    return self;
}
-(void)doUpdate:(ccTime)delta
{
    
    if(n.MountedObject)
    {
        // set the row and column equal to the current container's position
        
        int myColumn = n.myCol;
        int myRope = n.myRope;
        int myRow = n.myRow;
        
        // if we haven't done the evaluation of the container to our left
        //if(!evalLeft)
        //{
        DWGameObject *moveToLeft = nil;
        
        // then if we're at a position > 0
        if(myRope > 0)
        {
            
            for(int i=myRope; i>0; i--)
            {
                // Check the object to our left (-1) for a mounted object
                DWPlaceValueNetGameObject *go = [[[gameWorld.Blackboard.AllStores objectAtIndex:myColumn]objectAtIndex:myRow] objectAtIndex:(i-1)];
                
                if(!go.MountedObject)
                {
                    moveToLeft = go;
                }
            }
            
            if(moveToLeft)
            {
                DWPlaceValueBlockGameObject *mountedObject = (DWPlaceValueBlockGameObject*)n.MountedObject;
                mountedObject.Mount=moveToLeft;
                mountedObject.AnimateMe=YES;
                mountedObject.PosX=((DWPlaceValueNetGameObject*)moveToLeft).PosX;
                mountedObject.PosY=((DWPlaceValueNetGameObject*)moveToLeft).PosY;
                [mountedObject handleMessage:kDWupdateSprite];
                [gameWorld handleMessage:kDWresetPositionEval andPayload:nil withLogLevel:0];
            }
            
        }
        evalLeft=YES;
        //}
        //if(!evalUp)
        ///{
        int moveToRow=-1;
        if(myRow > 0)
        {
            for(int i=myRow; i>0; i--)
            {
                DWPlaceValueNetGameObject *go = [[[gameWorld.Blackboard.AllStores objectAtIndex:myColumn] objectAtIndex:(i-1)] objectAtIndex:0];
                
                if(!go.MountedObject)
                {
                    moveToRow = i;
                }   
            }
        }
        
        if(moveToRow>=0)
        {
            
            for (DWPlaceValueNetGameObject *cgo in [[gameWorld.Blackboard.AllStores objectAtIndex:myColumn] objectAtIndex:myRow]) {
                DWPlaceValueBlockGameObject *moveObject = (DWPlaceValueBlockGameObject*)cgo.MountedObject;
                int rope=cgo.myRope;
                if(moveObject)
                {
                    moveObject.Mount=[[[gameWorld.Blackboard.AllStores objectAtIndex:myColumn] objectAtIndex:(myRow-1)] objectAtIndex:rope];
                    moveObject.AnimateMe=YES;
                    moveObject.PosX=((DWPlaceValueNetGameObject*)moveObject.Mount).PosX;
                    moveObject.PosY=((DWPlaceValueNetGameObject*)moveObject.Mount).PosY;
                    [moveObject handleMessage:kDWupdateSprite];
                }
            }
        }            
        //[gameObject handleMessage:kDWresetPositionEval];
        //}
    }
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMountedObject)
    {
        //set the mount for the GO
        evalLeft = NO;
        evalUp = NO;
        
        
        //        n.MountedObject=gameObject;
        [[gameWorld GameScene] problemStateChanged];
        
    }
    
    if(messageType==kDWunsetMountedObject)
    {
        n.MountedObject=nil;
    }
    if(messageType==kDWresetPositionEval)
    {
        evalLeft=NO;
        evalUp=NO;
    }
}

@end
