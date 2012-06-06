//
//  BPieSplitterSliceObjectRender.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "BPieSplitterSliceObjectRender.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"
#import "DWGameWorld.h"
#import "AppDelegate.h"
#import "UsersService.h"

@interface BPieSplitterSliceObjectRender()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BPieSplitterSliceObjectRender

-(BPieSplitterSliceObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPieSplitterSliceObjectRender*)[super initWithGameObject:aGameObject withData:data];
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    contentService = ac.contentService;
    usersService = ac.usersService;
    
    //init pos x & y in case they're not set elsewhere
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        //if(!tile.mySprite) 
        //{
        //    [self setSprite];     
        //}
    }
    
    if(messageType==kDWupdateSprite)
    {
        //if(!tile.mySprite) { 
        //    [self setSprite];
        //}
        
    }
    if(messageType==kDWdismantle)
    {
        //[[tile.mySprite parent] removeChild:tile.mySprite cleanup:YES];
    } 
    
}



-(void)setSprite
{    
    
    NSString *spriteFileName=[[NSString alloc]init];
    //[[gameWorld GameSceneLayer] addChild:mySprite z:1];
    
    
    spriteFileName=[NSString stringWithFormat:@"/images/timestables/tile.png"];
    
    //tile.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    //[tile.mySprite setPosition:tile.Position];
        
//    if(gameWorld.Blackboard.inProblemSetup)
//    {
//        [tile.mySprite setTag:1];
//        [tile.mySprite setOpacity:0];
//    }
    
    
    
//    [[gameWorld Blackboard].ComponentRenderLayer addChild:tile.mySprite z:2];
    
}

-(void)handleTap
{
}

-(void) dealloc
{
    [super dealloc];
}

@end
