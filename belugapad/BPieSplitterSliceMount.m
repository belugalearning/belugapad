//
//  BPieSplitterSliceMount.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "BPieSplitterSliceMount.h"
#import "DWPieSplitterSliceGameObject.h"
#import "global.h"
#import "SimpleAudioEngine.h"

@implementation BPieSplitterSliceMount

-(BPieSplitterSliceMount *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPieSplitterSliceMount*)[super initWithGameObject:aGameObject withData:data];
    slice=(DWPieSplitterSliceGameObject*)gameObject;
    
    NSMutableArray *mo=[[NSMutableArray alloc] init];
    GOS_SET(mo, MOUNTED_OBJECTS);
    [mo release];
    
    return self;
}
-(void)doUpdate:(ccTime)delta
{

}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMount)
    {
        [self mountMeToContainer];
    }
    if(messageType==kDWunsetMount)
    {
        [self unMountMeFromContainer];
    }
}

-(void)mountMeToContainer
{
    if(slice.myCont){
        [slice.myCont handleMessage:kDWunsetMountedObject];
        slice.myCont=nil;
    }
    
    if(gameWorld.Blackboard.DropObject)
    {
        slice.myCont=gameWorld.Blackboard.DropObject;
        slice.Position=((DWPieSplitterSliceGameObject*)gameWorld.Blackboard.DropObject).Position;
        [slice handleMessage:kDWmoveSpriteToPosition];
    }
}
-(void)unMountMeFromContainer
{
    slice.myCont=nil;
}

@end
