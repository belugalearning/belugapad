//
//  BPieSplitterSliceObjectRender.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "BPieSplitterSliceObjectRender.h"
#import "DWPieSplitterSliceGameObject.h"
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
    slice=(DWPieSplitterSliceGameObject*)gameObject;
    
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
        if(!slice.mySprite) 
        {
            [self setSprite];     
        }
    }
    
    if(messageType==kDWupdateSprite)
    {
        if(!slice.mySprite) { 
            [self setSprite];
        }
        
    }
    if(messageType==kDWdismantle)
    {
        [[slice.mySprite parent] removeChild:slice.mySprite cleanup:YES];
    } 
    
}



-(void)setSprite
{    
    
    NSString *spriteFileName=[[NSString alloc]init];
    
    
    spriteFileName=[NSString stringWithFormat:@"/images/piesplitter/slice.png"];
    
    slice.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    [slice.mySprite setPosition:slice.Position];
        
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [slice.mySprite setTag:1];
        [slice.mySprite setOpacity:0];
    }
    
    
    
    [[gameWorld Blackboard].ComponentRenderLayer addChild:slice.mySprite z:2];
    
}

-(void)handleTap
{
}

-(void) dealloc
{
    [super dealloc];
}

@end
