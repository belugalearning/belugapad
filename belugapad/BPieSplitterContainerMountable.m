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
-(void)setMountedObject
{
    
}

-(void)checkDropTarget:(CGPoint)hitLoc
{
    if(CGRectContainsPoint(cont.mySprite.boundingBox, hitLoc))
   {
       gameWorld.Blackboard.DropObject=cont;
   }
}

-(void)mountObjectToMe
{
    if(gameWorld.Blackboard.PickupObject)
    {
        if(!cont.myText)
        {
            cont.myText=[CCLabelTTF labelWithString:@"" fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
            [cont.myText setPosition:ccp(50,-10)];
            [cont.mySprite addChild:cont.myText];
        }
        
        if(!cont.mySlices)cont.mySlices=[[NSMutableArray alloc]init];
        [cont.mySlices addObject:gameWorld.Blackboard.PickupObject];
        [cont.myText setString:[NSString stringWithFormat:@"%d", [cont.mySlices count]]];
    }
}
-(void)unMountObjectFromMe
{
    if(gameWorld.Blackboard.PickupObject && [cont.mySlices containsObject:gameWorld.Blackboard.PickupObject])
    {
        [cont.mySlices removeObject:gameWorld.Blackboard.PickupObject];
        if(cont.myText)[cont.myText setString:[NSString stringWithFormat:@"%d", [cont.mySlices count]]];
    }
}

@end
