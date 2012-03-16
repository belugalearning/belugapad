//
//  BMount.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueMount.h"
#import "global.h"
#import "SimpleAudioEngine.h"
#import "PlaceValue.h"

@implementation BPlaceValueMount

-(BPlaceValueMount *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueMount*)[super initWithGameObject:aGameObject withData:data];
    
    NSMutableArray *mo=[[NSMutableArray alloc] init];
    GOS_SET(mo, MOUNTED_OBJECTS);
    [mo release];
    
    return self;
}
-(void)doUpdate:(ccTime)delta
{
        if([[gameObject store] objectForKey:MOUNTED_OBJECT])
        {
            // set the row and column equal to the current container's position
            
            int myColumn = [[[gameObject store] objectForKey:PLACEVALUE_COLUMN] intValue];
            int myRope = [[[gameObject store] objectForKey:PLACEVALUE_ROPE] intValue];
            int myRow = [[[gameObject store] objectForKey:PLACEVALUE_ROW] intValue];
            
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
                        DWGameObject *go = [[[gameWorld.Blackboard.AllStores objectAtIndex:myColumn]objectAtIndex:myRow] objectAtIndex:(i-1)];
                        
                        if(![[go store] objectForKey:MOUNTED_OBJECT])
                        {
                            moveToLeft = go;
                        }
                    }
                    
                    if(moveToLeft)
                    {
                        DWGameObject *mountedObject = [[gameObject store] objectForKey:MOUNTED_OBJECT];
                        NSMutableDictionary *pl = [NSMutableDictionary dictionaryWithObject:moveToLeft forKey:MOUNT];
                        [pl setObject:[NSNumber numberWithBool:YES] forKey:ANIMATE_ME];
                        
                        [mountedObject handleMessage:kDWsetMount andPayload:pl withLogLevel:0];
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
                        DWGameObject *go = [[[gameWorld.Blackboard.AllStores objectAtIndex:myColumn] objectAtIndex:(i-1)] objectAtIndex:0];
                        
                        if(![[go store] objectForKey:MOUNTED_OBJECT])
                        {
                            DLog(@"we have empty space above");
                            moveToRow = i;
                        }   
                    }
                }
                
               if(moveToRow>=0)
                {
                    
                    for (DWGameObject *cgo in [[gameWorld.Blackboard.AllStores objectAtIndex:myColumn] objectAtIndex:myRow]) {
                        DWGameObject *moveObject = [[cgo store] objectForKey:MOUNTED_OBJECT];
                        int rope=[[[cgo store] objectForKey:PLACEVALUE_ROPE] intValue];
                        if(moveObject)
                        {
                            NSMutableDictionary *pl = [NSMutableDictionary dictionaryWithObject:[[[gameWorld.Blackboard.AllStores objectAtIndex:myColumn] objectAtIndex:(myRow-1)] objectAtIndex:rope] forKey:MOUNT];
                            [pl setObject:[NSNumber numberWithBool:YES] forKey:ANIMATE_ME];
                            [moveObject handleMessage:kDWsetMount andPayload:pl withLogLevel:0];

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

        
        DWGameObject *addO=[payload objectForKey:MOUNTED_OBJECT];
        [[gameObject store] setObject:addO forKey:MOUNTED_OBJECT];
        [[gameWorld GameScene] problemStateChanged];
        
        if([[gameObject store] objectForKey:ALLOW_MULTIPLE_MOUNT])
        {
            [addO handleMessage:kDWdeselectAll];
        }
    }
    
    if(messageType==kDWunsetMountedObject)
    {
        [[gameObject store] removeObjectForKey:MOUNTED_OBJECT];
    }
    if(messageType==kDWresetPositionEval)
    {
        evalLeft=NO;
        evalUp=NO;
    }
}

@end
