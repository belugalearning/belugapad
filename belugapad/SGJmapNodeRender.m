//
//  SGJmapNodeRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGJmapNodeRender.h"
#import "SGJmapNode.h"

@interface SGJmapNodeRender()
{
    CCSprite *nodeSprite;
}

@end

@implementation SGJmapNodeRender

-(SGJmapNodeRender*)initWithGameObject:(id<Transform, ProximityResponder>)aGameObject
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
    [ParentGO.RenderBatch addChild:nodeSprite z:2];
}



@end
