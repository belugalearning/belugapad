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
    CGRect baseNodeBound=CGRectNull;
    baseNodeBound=CGRectUnion(cont.mySpriteTop.boundingBox, cont.mySpriteBot.boundingBox);
    
    if(CGRectContainsPoint(baseNodeBound, [cont.BaseNode convertToNodeSpace:hitLoc]))
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

        float scaleForMid=0.4*([cont.Nodes count]-1);
        scaleForMid+=1;
        NSLog(@"scaleForMid %f", scaleForMid);        
        if(scaleForMid>=1.0f)
        {
            [cont.mySpriteMid setScaleY:scaleForMid];

            [cont.mySpriteMid setAnchorPoint:ccp(0.5,-1)];
            
            [cont.mySpriteMid setPosition:ccp(0,0-((cont.mySpriteTop.contentSize.height*[cont.Nodes count])+(cont.mySpriteMid.contentSize.height*cont.mySpriteMid.scaleY)-(cont.mySpriteTop.contentSize.height*(scaleForMid-1))))];
            
            [cont.mySpriteBot setPosition:ccp(0,-(cont.mySpriteTop.contentSize.height+(cont.mySpriteMid.contentSize.height*cont.mySpriteMid.scaleY)-(cont.mySpriteTop.contentSize.height*(scaleForMid-1))))];
            //[cont.mySpriteMid runAction:[CCScaleTo actionWithDuration:0.5f scaleX:cont.mySpriteMid.scaleX scaleY:scaleForMid]];
            //[cont.mySpriteTop runAction:[CCMoveTo actionWithDuration:0.5f position:ccp(0,(cont.mySpriteMid.contentSize.height)-(cont.mySpriteTop.contentSize.height/2))]];
            //[cont.mySpriteBot runAction:[CCMoveTo actionWithDuration:0.5f position:ccp(0,0-(cont.mySpriteMid.contentSize.height/2)-(cont.mySpriteTop.contentSize.height/2))]];
        }
    }
}
-(void)unMountObjectFromMe
{
    if(gameWorld.Blackboard.PickupObject && [cont.mySlices containsObject:gameWorld.Blackboard.PickupObject])
    {
        [cont.mySlices removeObject:gameWorld.Blackboard.PickupObject];
        if(cont.myText)[cont.myText setString:[NSString stringWithFormat:@"%d", [cont.mySlices count]]];
        
        float scaleForMid=0.4*([cont.Nodes count]-1);
        scaleForMid+=1;
        NSLog(@"scaleForMid %f", scaleForMid);        
        if(scaleForMid>=1.0f)
        {
            [cont.mySpriteTop setAnchorPoint:ccp(0.5,-1)];    
            [cont.mySpriteMid setAnchorPoint:ccp(0.5,-1)];
            [cont.mySpriteBot setAnchorPoint:ccp(0.5,-1)];
            [cont.mySpriteMid setScaleY:scaleForMid];
            
            [cont.mySpriteMid setPosition:ccp(0,0-((cont.mySpriteTop.contentSize.height*[cont.Nodes count])+(cont.mySpriteMid.contentSize.height*cont.mySpriteMid.scaleY)-(cont.mySpriteTop.contentSize.height*(scaleForMid-1))))];
            
            [cont.mySpriteBot setPosition:ccp(0,-(cont.mySpriteTop.contentSize.height+(cont.mySpriteMid.contentSize.height*cont.mySpriteMid.scaleY)-(cont.mySpriteTop.contentSize.height*(scaleForMid-1))))];
            //[cont.mySpriteMid runAction:[CCScaleTo actionWithDuration:0.5f scaleX:cont.mySpriteMid.scaleX scaleY:scaleForMid]];
            //[cont.mySpriteTop runAction:[CCMoveTo actionWithDuration:0.5f position:ccp(0,(cont.mySpriteMid.contentSize.height)-(cont.mySpriteTop.contentSize.height/2))]];
            //[cont.mySpriteBot runAction:[CCMoveTo actionWithDuration:0.5f position:ccp(0,0-(cont.mySpriteMid.contentSize.height/2)-(cont.mySpriteTop.contentSize.height/2))]];
        }
        
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
