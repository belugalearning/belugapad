//
//  BPieSplitterSliceMount.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "BPieSplitterSliceMount.h"
#import "DWPieSplitterSliceGameObject.h"
#import "DWPieSplitterPieGameObject.h"
#import "DWPieSplitterContainerGameObject.h"
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
        DWPieSplitterContainerGameObject *c=(DWPieSplitterContainerGameObject*)slice.myCont;
        
        slice.Position=((DWPieSplitterContainerGameObject*)gameWorld.Blackboard.DropObject).Position;
        
        //flip ownership of the sprite from the pie to the container
        [slice.mySprite removeFromParentAndCleanup:YES];
        slice.mySprite=nil;
        slice.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/slice.png")];
        
        [c.mySprite addChild:slice.mySprite];
        


        
        [slice handleMessage:kDWmoveSpriteToPosition];
    }
}
-(void)unMountMeFromContainer
{
    DWPieSplitterPieGameObject *p=(DWPieSplitterPieGameObject*)slice.myPie;        
    [slice.mySprite removeFromParentAndCleanup:YES];
    slice.mySprite=nil;
    slice.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/piesplitter/slice.png")];
    [p.mySprite addChild:slice.mySprite];
    [slice setPosition:[p.mySprite convertToNodeSpace:slice.Position]];
    
    slice.myCont=nil;
}

@end
