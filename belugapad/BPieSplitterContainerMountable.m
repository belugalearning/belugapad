//
//  BPieSplitterContainerMountable.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "BPieSplitterContainerMountable.h"
#import "DWPieSplitterContainerGameObject.h"
#import "DWPieSplitterSliceGameObject.h"
#import "DWPieSplitterPieGameObject.h"

@implementation BPieSplitterContainerMountable


-(BPieSplitterContainerMountable *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPieSplitterContainerMountable *)[super initWithGameObject:aGameObject withData:data];
    cont=(DWPieSplitterContainerGameObject*)gameObject;

    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetMountedObject)
    {
        [self mountObjectToMe];
    }
    if(messageType==kDWunsetMountedObject)
    {
        [self unMountObjectFromMe];
    }
    if(messageType==kDWdismantle)
    {

    }
    if(messageType==kDWareYouADropTarget)
    {
        CGPoint loc=[[payload objectForKey:POS] CGPointValue];
        [self checkDropTarget:loc]; 
    }
}

-(void)checkDropTarget:(CGPoint)hitLoc
{
    if(CGRectContainsPoint(cont.mySprite.boundingBox, [cont.BaseNode convertToNodeSpace:hitLoc]))
   {
       gameWorld.Blackboard.DropObject=cont;
   }
}

-(void)mountObjectToMe
{
    if(gameWorld.Blackboard.PickupObject)
    {
        if(!cont.mySlices)cont.mySlices=[[NSMutableArray alloc]init];
        
        [cont.mySlices addObject:gameWorld.Blackboard.PickupObject];
        
        [gameWorld.Blackboard.PickupObject handleMessage:kDWmoveSpriteToPosition];
        
    }
}
-(void)unMountObjectFromMe
{
    if(gameWorld.Blackboard.PickupObject && [cont.mySlices containsObject:gameWorld.Blackboard.PickupObject])
    {
        [cont.mySlices removeObject:gameWorld.Blackboard.PickupObject];
        if(cont.myText)[cont.myText setString:[NSString stringWithFormat:@"%d", [cont.mySlices count]]];
        
        // reorder pie slices
        for(int i=0;i<[cont.mySlices count];i++)
        {
            DWPieSplitterSliceGameObject *sl=[cont.mySlices objectAtIndex:i];
            DWPieSplitterPieGameObject *p=(DWPieSplitterPieGameObject*)sl.myPie;
            
            CCSprite *s=sl.mySprite;
            [s runAction:[CCRotateTo actionWithDuration:0.1f angle:(360/p.numberOfSlices)*i]];
        }
        
    }
}

@end
