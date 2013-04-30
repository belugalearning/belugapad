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
    if(messageType==kSGsetVisualStateAfterBuildUp)
    {
        [self decideOnPinState];
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
    
    bool isHomework=NO;
    bool isDoNow=NO;
    
    if([pn.ustate.assignmentFlags containsObject:@"homework"])
        isHomework=YES;
    
    if([pn.ustate.assignmentFlags containsObject:@"doNow"])
        isDoNow=YES;
    
    if(isHomework || isDoNow)
    {
        //isdonow takes priority
        if(isDoNow)
            nodeSprite=[CCSprite spriteWithSpriteFrameName:@"checkerd_flag_right.png"];
        else
            nodeSprite=[CCSprite spriteWithSpriteFrameName:@"homework_flag_right.png"];
    }
    
    else
    {
        if(pn.EnabledAndComplete)
        {
            //should be blue
            nodeSprite=[CCSprite spriteWithSpriteFrameName:@"Node_Complete_Right.png"];
        }
        else if (pn.Attempted)
        {
            //should be yellow
            nodeSprite=[CCSprite spriteWithSpriteFrameName:@"Node_Attempted_Right.png"];
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
    }
    
    CGPoint offset=ccp(nodeSprite.contentSize.width / 2.0f, -nodeSprite.contentSize.height / 2.0f);
    ParentGO.Position=ccpAdd(ParentGO.Position, offset);
    
    [nodeSprite setPosition:ccpAdd(ParentGO.Position, offset)];
    [nodeSprite setVisible:YES];
    [ParentGO.RenderBatch addChild:nodeSprite z:6];
    

    
    if(((AppController*)[[UIApplication sharedApplication] delegate]).AuthoringMode)
    {
        labelSprite=[CCLabelTTF labelWithString:ParentGO.UserVisibleString fontName:@"Source Sans Pro" fontSize:14.0f];
        [labelSprite setPosition:ParentGO.Position];
        [labelSprite setVisible:NO];
        [ParentGO.RenderBatch.parent addChild:labelSprite z:99];
    }
    
}

-(void)decideOnPinState
{
    SGJmapNode *pn=(SGJmapNode*)ParentGO;
    
    //if the node is on a 100% prqc island but isn't complete, bounce it
    if(pn.MasteryNode.PrereqPercentage>=50.0f && !pn.EnabledAndComplete && pn.MasteryNode.shouldBouncePins)
    {
        [self boundThisPin:nodeSprite];
    }
    
    //or if this is the SPECIAL node && not complete
    if([pn._id isEqualToString:@"5608a59d6797796ce9e11484fd180214"] && !pn.EnabledAndComplete)
    {
        [self boundThisPin:nodeSprite];
    }
}

-(void)boundThisPin:(CCSprite*)sprite
{
    //pick it up
    CCEaseInOut *ml1=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.1f scale:1.25f] rate:2.0f];
    
    //drop it
    CCEaseInOut *ml2=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.2f scale:0.95f] rate:2.0f];
    
    //pick it up
    CCEaseInOut *ml3=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.1f scale:1.15f] rate:2.0f];
    
    //drop it
    CCEaseInOut *ml4=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.2f scale:0.97f] rate:2.0f];
    
    //pick it up
    CCEaseInOut *ml5=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.1f scale:1.05f] rate:2.0f];
    
    //drop it
    CCEaseInOut *ml6=[CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:0.2f scale:1.0f] rate:2.0f];
    
    //delay -- random offset
    float randOffset=arc4random() % 10;
    
    CCDelayTime *dt=[CCDelayTime actionWithDuration:1.0f + (0.1f * randOffset)];
    
    CCSequence *s=[CCSequence actions:ml1, ml2, ml3, ml4, ml5, ml6, dt, nil];
    
    CCEaseInOut *oe=[CCEaseInOut actionWithAction:s rate:2.0f];
    
    //repeat
    CCRepeatForever *rf=[CCRepeatForever actionWithAction:oe];
    
    [sprite runAction:rf];
}

-(void)flipSprite
{
    nodeSprite.flipX=ParentGO.flip;
}

-(void)setupArtefact
{
    NSString *an=@"star_holder_0.png";
    if(ParentGO.ustate.artifact1LastAchieved)an=@"star_holder_1.png";
    if(ParentGO.ustate.artifact2LastAchieved)an=@"star_holder_2.png";
    if(ParentGO.ustate.artifact3LastAchieved)an=@"star_holder_3.png";
    if(ParentGO.ustate.artifact4LastAchieved)an=@"star_holder_3.png";
    if(ParentGO.ustate.artifact5LastAchieved)an=@"star_holder_3.png";
    
//    if(an) [ParentGO.artefactSpriteBase setDisplayFrame:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:an]];
    
    if(an)
    {
        CCSprite *stars=[CCSprite spriteWithSpriteFrameName:an];
        
        if(nodeSprite.flipX)
            stars.position=ccpAdd(ParentGO.Position, ccp(-6, 50));
        else
            stars.position=ccpAdd(ParentGO.Position, ccp(6, 50));
        
        [ParentGO.RenderBatch addChild:stars z:7];
    }
    
}


@end
