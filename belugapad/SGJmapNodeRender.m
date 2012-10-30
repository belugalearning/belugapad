//
//  SGJmapNodeRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapNodeRender.h"
#import "SGJmapNode.h"
#import "SGJmapMasteryNode.h"

#import "BLMath.h"
#import "AppDelegate.h"

@interface SGJmapNodeRender()
{
    CCSprite *nodeSprite;
    CCSprite *labelSprite;
}

@end

@implementation SGJmapNodeRender

-(SGJmapNodeRender*)initWithGameObject:(SGJmapNode*)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    if(messageType==kSGvisibilityChanged)
    {
        nodeSprite.visible=ParentGO.Visible;
    }
    
    if(messageType==kSGzoomOut)
    {
        [nodeSprite setVisible:YES];
        [nodeSprite setOpacity:50];
    }
    if(messageType==kSGzoomIn)
    {
        [nodeSprite setOpacity:255];
    }
    if(messageType==kSGretainOffsetPosition)
    {
        positionAsOffset=[BLMath SubtractVector:ParentGO.Position from:ParentGO.MasteryNode.Position];
    }
    if(messageType==kSGresetPositionUsingOffset)
    {
        ParentGO.Position=[BLMath AddVector:ParentGO.MasteryNode.Position toVector:positionAsOffset];
        [self updatePosition:ParentGO.Position];
    }
    
    //authoring mode stuff
    if(messageType==kSGenableAuthorRender)
    {
        if(labelSprite)labelSprite.visible=YES;
    }
    if(messageType==kSGdisableAuthorRender)
    {
        if(labelSprite)labelSprite.visible=NO;
    }
}

-(void)doUpdate:(ccTime)delta
{

}

-(void)draw:(int)z
{
//    CGPoint lp=[ParentGO.RenderBatch.parent convertToWorldSpace:ParentGO.Position];
//    
//    //glLineWidth(6.0f);
//    ccDrawColor4B(255, 255, 255, 50);
//    ccDrawLine(lp, ccpAdd(lp, ccp(100,100)));

}

-(void)updatePosition:(CGPoint)pos
{
    [nodeSprite setPosition:pos];
    if(labelSprite)labelSprite.position=pos;
}

-(void)setup
{
    if(((SGJmapNode*)ParentGO).EnabledAndComplete)
    {
        nodeSprite=[CCSprite spriteWithSpriteFrameName:@"node-complete.png"];
    }
    else 
    {
        nodeSprite=[CCSprite spriteWithSpriteFrameName:@"node-incomplete.png"];
    }
    
    [nodeSprite setPosition:ParentGO.Position];
    [nodeSprite setVisible:ParentGO.Visible];
    [ParentGO.RenderBatch addChild:nodeSprite z:5];
    
    if(ParentGO.flip) nodeSprite.flipX=YES;
    
    if(((AppController*)[[UIApplication sharedApplication] delegate]).AuthoringMode)
    {
        labelSprite=[CCLabelTTF labelWithString:ParentGO.UserVisibleString fontName:@"Source Sans Pro" fontSize:14.0f];
        [labelSprite setPosition:ParentGO.Position];
        [labelSprite setVisible:NO];
        [ParentGO.RenderBatch.parent addChild:labelSprite z:99];
    }
    
}




@end
