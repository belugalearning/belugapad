//
//  SGDtoolBlockRender.m
//  belugapad
//
//  Created by David Amphlett on 03/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "SGDtoolBlockRender.h"
#import "SGDtoolBlock.h"
#import "BLMath.h"

@interface SGDtoolBlockRender()
{
    CCSprite *blockSprite;
}

@end

@implementation SGDtoolBlockRender

-(SGDtoolBlockRender*)initWithGameObject:(id<Transform, Moveable, Pairable>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{

}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)drawProximateLines:(CGPoint)location
{
    if([ParentGO.PairedObjects count]>0)
    {
        ccDrawColor4F(0, 255, 0, 255);
        ccDrawLine(ParentGO.Position, location);
    }
}

-(void)drawNotProximateLines:(CGPoint)location
{
    if([ParentGO.PairedObjects count]>0)
    {
        ccDrawColor4F(255, 0, 0, 255);
        ccDrawLine(ParentGO.Position, location);
    }
}


-(void)setup
{

    //blockSprite=[CCSprite spriteWithSpriteFrameName:@"node-complete.png"];
    blockSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/distribution/block.png")];
    ParentGO.mySprite=blockSprite;
    [blockSprite setPosition:ParentGO.Position];
    [blockSprite setVisible:ParentGO.Visible];
    [ParentGO.RenderLayer addChild:blockSprite];
}

-(void)move
{
    [blockSprite setPosition:ParentGO.Position];
}

-(void)animateToPosition
{
    [blockSprite runAction:[CCMoveTo actionWithDuration:0.2f position:ParentGO.Position]];
}

-(BOOL)amIProximateTo:(CGPoint)location
{
    ParentGO.SeekingPair=YES;
    if([BLMath DistanceBetween:ParentGO.Position and:location]<100.0f)
    {
        [ParentGO.mySprite setColor:ccc3(0,255,0)];
        //[self drawProximateLines:location];
        return YES;
    }
    else {
        [ParentGO.mySprite setColor:ccc3(255,255,255)];
        //[self drawNotProximateLines:location];
        return NO;
    }
    ParentGO.SeekingPair=NO;
}

-(void)resetTint
{
    [ParentGO.mySprite setColor:ccc3(255,255,255)];
}

@end
