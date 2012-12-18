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
    CCSprite *artefactSprite;
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
        nodeSprite.visible=YES;
    }
    
    if(messageType==kSGzoomOut)
    {
//        [nodeSprite setVisible:YES];
//        [nodeSprite setOpacity:50];
    }
    if(messageType==kSGzoomIn)
    {
//        [nodeSprite setOpacity:255];
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
    SGJmapNode *pn=(SGJmapNode*)ParentGO;
    
    if(pn.EnabledAndComplete)
    {
        //should be blue
        nodeSprite=[CCSprite spriteWithSpriteFrameName:@"Node_Complete_Right.png"];
    }
    else if (pn.Attempted)
    {
        //should be yellow
        nodeSprite=[CCSprite spriteWithSpriteFrameName:@"Node_Incomplete_Right.png"];
    }
    else if(pn.MasteryNode.PrereqPercentage>0)
    {
        //should be red
        nodeSprite=[CCSprite spriteWithSpriteFrameName:@"Node_Incomplete_Right.png"];
    }
    else
    {
        //should be a stalk / stump
        nodeSprite=[CCSprite spriteWithSpriteFrameName:@"Node_Incomplete_Right.png"];
    }
    
    [nodeSprite setPosition:ParentGO.Position];
    [nodeSprite setVisible:YES];
    [ParentGO.RenderBatch addChild:nodeSprite z:6];
    
    if(ParentGO.flip)
    {
     nodeSprite.color=ccc3(255, 0, 0);   
    }
    
    if(((AppController*)[[UIApplication sharedApplication] delegate]).AuthoringMode)
    {
        labelSprite=[CCLabelTTF labelWithString:ParentGO.UserVisibleString fontName:@"Source Sans Pro" fontSize:14.0f];
        [labelSprite setPosition:ParentGO.Position];
        [labelSprite setVisible:NO];
        [ParentGO.RenderBatch.parent addChild:labelSprite z:99];
    }
    
}

-(void)setupArtefact
{
    NSString *an=nil;
    if(ParentGO.ustate.artifact1LastAchieved)an=@"Crystal_1.png";
    if(ParentGO.ustate.artifact2LastAchieved)an=@"Crystal_2.png";
    if(ParentGO.ustate.artifact3LastAchieved)an=@"Crystal_3.png";
    if(ParentGO.ustate.artifact4LastAchieved)an=@"Crystal_4.png";
    if(ParentGO.ustate.artifact5LastAchieved)an=@"Crystal_5.png";
    
    if(an) [ParentGO.artefactSpriteBase setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:an]];
}


@end
