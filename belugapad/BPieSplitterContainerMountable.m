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
    if(messageType==kDWunsetAllMountedObjects)
    {
        [self unMountAllMountedObjectsFromMe];
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
    CGRect baseNodeBound=CGRectNull;
    baseNodeBound=CGRectUnion(cont.mySprite.boundingBox, cont.mySprite.boundingBox);
    
    if(CGRectContainsPoint(baseNodeBound, [cont.BaseNode convertToNodeSpace:hitLoc]))
   {
       gameWorld.Blackboard.DropObject=cont;
   }
}

-(void)mountObjectToMe
{
    if(gameWorld.Blackboard.PickupObject)
    {
        if(!cont.mySlices)cont.mySlices=[[[NSMutableArray alloc]init] autorelease];
        NSLog(@"before mounted objects: %d",[cont.mySlices count]);
        [cont.mySlices addObject:gameWorld.Blackboard.PickupObject];
        NSLog(@"after mounted objects: %d",[cont.mySlices count]);
        //        [self scaleMidSection];
    }
}
-(void)unMountObjectFromMe
{
    if(gameWorld.Blackboard.PickupObject && [cont.mySlices containsObject:gameWorld.Blackboard.PickupObject])
    {
        [cont.mySlices removeObject:gameWorld.Blackboard.PickupObject];
        if(cont.myText)[cont.myText setString:[NSString stringWithFormat:@"%d", [cont.mySlices count]]];
        
//        [self scaleMidSection];
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

-(void)unMountAllMountedObjectsFromMe
{
    [cont.mySlices removeAllObjects];
    [cont.Nodes removeAllObjects];
    NSLog(@"basenode child count: %d",[cont.BaseNode.children count]);
    if(cont.myText)[cont.myText setString:[NSString stringWithFormat:@"%d", [cont.mySlices count]]];
    
    //[self scaleMidSection];

}

-(void)scaleMidSection
{
    float scaleForMid=0.4*([cont.Nodes count]-1);
    scaleForMid+=1;
    if([cont.Nodes count]==0)scaleForMid=1.0f;
    NSLog(@"scaleForMid %f", scaleForMid); 
    if(scaleForMid>=1.0f)
    {
        [cont.mySprite setScaleY:scaleForMid];

    }
}

@end
