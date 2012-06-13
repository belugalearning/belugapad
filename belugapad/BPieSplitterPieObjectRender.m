//
//  BPieSplitterPieObjectRender.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "BPieSplitterPieObjectRender.h"
#import "DWPieSplitterPieGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"
#import "DWGameWorld.h"
#import "AppDelegate.h"
#import "UsersService.h"

@interface BPieSplitterPieObjectRender()
{
@private
    ContentService *contentService;
    UsersService *usersService;
}

@end

@implementation BPieSplitterPieObjectRender

-(BPieSplitterPieObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPieSplitterPieObjectRender*)[super initWithGameObject:aGameObject withData:data];
    pie=(DWPieSplitterPieGameObject*)gameObject;
    
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
        if(!pie.mySprite) 
        {
            [self setSprite];     
        }
    }
    
    if(messageType==kDWupdateSprite)
    {
        if(!pie.mySprite) { 
            [self setSprite];
        }
        
    }
    if(messageType==kDWmoveSpriteToPosition)
    {
        [self moveSprite];
    }
    if(messageType==kDWresetToMountPosition)
    {
        [self moveSpriteHome];
    }
    if(messageType==kDWdismantle)
    {
        [[pie.mySprite parent] removeChild:pie.mySprite cleanup:YES];
    } 
    if(messageType==kDWsplitActivePies)
    {
        CCLabelTTF *lbl=[CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d",pie.numberOfSlices] fontName:PROBLEM_DESC_FONT fontSize:PROBLEM_DESC_FONT_SIZE];
        [lbl setPosition:ccp(50,50)];
        [pie.mySprite addChild:lbl];
        [pie.mySprite removeChild:pie.touchOverlay cleanup:YES];
    }
    
    
}



-(void)setSprite
{    
    
    NSString *spriteFileName=[[NSString alloc]init];
    spriteFileName=[NSString stringWithFormat:@"/images/piesplitter/pie.png"];
    
    pie.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    [pie.mySprite setPosition:pie.Position];
    if(!pie.ScaledUp)[pie.mySprite setScale:0.5f];
    else [pie.mySprite setScale:1.0f];
    
        if(gameWorld.Blackboard.inProblemSetup)
        {
            [pie.mySprite setTag:1];
            [pie.mySprite setOpacity:0];
        }
    
    if(!pie.HasSplit) {
        NSString *overlayFileName=[[NSString alloc]init];
        overlayFileName=[NSString stringWithFormat:@"/images/piesplitter/pie-split-overlay.png"];
        pie.touchOverlay=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(overlayFileName)];
        [pie.touchOverlay setPosition:ccp(50,50)];
        [pie.mySprite addChild:pie.touchOverlay];
        if(gameWorld.Blackboard.inProblemSetup)
        {
            [pie.touchOverlay setTag:1];
            [pie.touchOverlay setOpacity:0];
        }
    }
    
    
        [[gameWorld Blackboard].ComponentRenderLayer addChild:pie.mySprite z:2];
    
}

-(void)moveSprite
{
    if(!pie.ScaledUp)
    {
        [pie.mySprite runAction:[CCScaleTo actionWithDuration:0.2f scale:1.0f]];
        pie.ScaledUp=YES;
    }
    [pie.mySprite setPosition:pie.Position];
}

-(void)moveSpriteHome
{
    if(pie.ScaledUp){
        [pie.mySprite runAction:[CCScaleTo actionWithDuration:0.2f scale:0.5f]];
        pie.ScaledUp=NO;
    }
    [pie.mySprite runAction:[CCMoveTo actionWithDuration:0.5f position:pie.MountPosition]];
}

-(void)handleTap
{
}

-(void) dealloc
{
    [super dealloc];
}

@end