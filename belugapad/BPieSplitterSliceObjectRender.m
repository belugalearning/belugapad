//
//  BPieSplitterSliceObjectRender.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "BPieSplitterSliceObjectRender.h"
#import "DWPieSplitterSliceGameObject.h"
#import "DWPieSplitterPieGameObject.h"
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
    if(messageType==kDWmoveSpriteToPosition)
    {
        [self moveSprite];
    }
    if(messageType==kDWmoveSpriteToHome)
    {
        [self moveSpriteHome];
    }
    if(messageType==kDWdismantle)
    {
        [[slice.mySprite parent] removeChild:slice.mySprite cleanup:YES];
    } 
    
}



-(void)setSprite
{    
    DWPieSplitterPieGameObject *p=(DWPieSplitterPieGameObject*)slice.myPie;
    NSString *spriteFileName=[[NSString alloc]init];
    
    spriteFileName=[NSString stringWithFormat:@"/images/piesplitter/slice.png"];
    
    slice.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    [slice.mySprite setPosition:[p.mySprite convertToNodeSpace:slice.Position]];
    
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [slice.mySprite setTag:1];
        [slice.mySprite setOpacity:0];
    }
    
    
    
    [p.mySprite addChild:slice.mySprite];
    
    
}
-(void)moveSprite
{
    DWPieSplitterPieGameObject *pie=(DWPieSplitterPieGameObject*)slice.myPie;
    [slice.mySprite setPosition:[pie.mySprite convertToNodeSpace:slice.Position]];
}
-(void)moveSpriteHome
{
    DWPieSplitterPieGameObject *myPie=(DWPieSplitterPieGameObject*)slice.myPie;
    if(slice.myPie) {
        slice.Position=myPie.Position;
        [slice.mySprite runAction:[CCMoveTo actionWithDuration:0.5f position:[myPie.mySprite convertToNodeSpace: slice.Position]]];
    }
}
-(void)handleTap
{
}

-(void) dealloc
{
    [super dealloc];
}

@end
