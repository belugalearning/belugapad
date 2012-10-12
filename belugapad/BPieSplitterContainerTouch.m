//
//  BPieSplitterContainerTouch.m
//  belugapad
//
//  Created by David Amphlett on 07/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//


#import "BPieSplitterContainerTouch.h"
#import "DWPieSplitterContainerGameObject.h"
#import "DWPieSplitterSliceGameObject.h"

#import "global.h"
#import "ToolConsts.h"
#import "ToolHost.h"
#import "BLMath.h"
#import "AppDelegate.h"
#import "UsersService.h"

@interface BPieSplitterContainerTouch()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BPieSplitterContainerTouch

-(BPieSplitterContainerTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPieSplitterContainerTouch*)[super initWithGameObject:aGameObject withData:data];
    cont=(DWPieSplitterContainerGameObject *)gameObject;
    //init pos x & y in case they're not set elsewhere
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    contentService = ac.contentService;
    usersService = ac.usersService;
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWrenderSelection)
    {
        
    }
    
    if(messageType==kDWcanITouchYou)
    {
        CGPoint loc=[[payload objectForKey:POS] CGPointValue];
        [self checkTouch:loc];
    }
    
    if(messageType==kDWaddMeToSelection)
    {
        
    }
    
}

-(void)checkTouch:(CGPoint)hitLoc
{
    CGRect baseNodeBound=CGRectNull;
    baseNodeBound=CGRectUnion(cont.mySpriteTop.boundingBox, cont.mySpriteBot.boundingBox);
    
    if(CGRectContainsPoint(baseNodeBound, [cont.BaseNode convertToNodeSpace:hitLoc]) && [cont.mySlices count]==0)
    {
        gameWorld.Blackboard.PickupObject=gameObject;
    }
    // but - if we do have slices associated, then we want the container to respond and not the slice so that the ordering is right
    else if([cont.mySlices count]>0)
    {
        for(DWPieSplitterSliceGameObject *s in cont.mySlices)
        {
            if(CGRectContainsPoint(s.mySprite.boundingBox, [cont.BaseNode convertToNodeSpace:hitLoc]))
            {
                gameWorld.Blackboard.PickupObject=s;
            }
        }
    }
}

-(void) dealloc
{
    [super dealloc];
}

@end
