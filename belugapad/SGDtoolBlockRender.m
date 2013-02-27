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
#import "SGDtoolContainer.h"
#import "BLMath.h"

@interface SGDtoolBlockRender()
{
    CCSprite *blockSprite;
}

@end

@implementation SGDtoolBlockRender

-(SGDtoolBlockRender*)initWithGameObject:(id<Transform, Moveable, Pairable, Configurable, Selectable>)aGameObject
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


-(void)setup
{
    NSString *sprFileName=nil;
    
    if(!ParentGO.blockType){
        ParentGO.blockType=@"Circle";
    }
    else if([ParentGO.blockType isEqualToString:@"Random"])
    {
        int thisBlockType=0;
        
        thisBlockType=arc4random() % 5;
        
        if(thisBlockType==0)
            ParentGO.blockType=@"Circle";
        else if(thisBlockType==1)
            ParentGO.blockType=@"Diamond";
        else if(thisBlockType==2)
            ParentGO.blockType=@"Ellipse";
        else if(thisBlockType==3)
            ParentGO.blockType=@"House";
        else if(thisBlockType==4)
            ParentGO.blockType=@"RoundedSquare";
        else if(thisBlockType==5)
            ParentGO.blockType=@"Square";
    }

    sprFileName=[NSString stringWithFormat:@"/images/distribution/DT_Shape_%@.png", ParentGO.blockType];
    
    blockSprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(sprFileName)];
    ParentGO.mySprite=blockSprite;
    [blockSprite setPosition:ParentGO.Position];
    [blockSprite setVisible:ParentGO.Visible];
    [ParentGO.RenderLayer addChild:blockSprite];
}

-(void)move
{
    [blockSprite setPosition:ParentGO.Position];
    [ParentGO.Label setPosition:ParentGO.Position];
    if(ParentGO.MyContainer && [ParentGO.MyContainer isKindOfClass:[SGDtoolContainer class]])
    {
        SGDtoolContainer *c=(SGDtoolContainer*)ParentGO.MyContainer;
        if(c.blocksInShape==1)
        {
            [c.CountLabel setPosition:ccp(ParentGO.Position.x,ParentGO.Position.y-50)];
            [c.BTXERow setPosition:ccp(ParentGO.Position.x,ParentGO.Position.y+50)];
        }
    }
}

-(void)animateToPosition
{
    [blockSprite runAction:[CCMoveTo actionWithDuration:0.2f position:ParentGO.Position]];
}

-(BOOL)amIProximateTo:(CGPoint)location
{
    if([ParentGO.MyContainer conformsToProtocol:@protocol(Cage)])
        return NO;

    
    ParentGO.SeekingPair=YES;

    if([BLMath DistanceBetween:ParentGO.Position and:location]<gameWorld.Blackboard.MaxObjectDistance)
        return YES;
    else
        return NO;

    ParentGO.SeekingPair=NO;
}

-(void)destroyThisObject
{
    ParentGO.RenderLayer=nil;
    if(ParentGO.MyContainer)[(id<ShapeContainer>)ParentGO.MyContainer removeBlockFromMe:ParentGO];
    if(ParentGO.Label)[ParentGO.Label removeFromParentAndCleanup:YES];
    if(ParentGO.mySprite)[ParentGO.mySprite removeFromParentAndCleanup:YES];
    ParentGO.mySprite=nil;
    ParentGO.PairedObjects=nil;
    ParentGO.Label=nil;
    ParentGO.blockType=nil;
    
    
    [gameWorld delayRemoveGameObject:(id)ParentGO];
}

-(void)selectMe
{
    if(ParentGO.Selected)
    {
        [ParentGO.mySprite setColor:ccc3(255,255,255)];
        ParentGO.Selected=NO;
    }
    else if(!ParentGO.Selected)
    {
        [ParentGO.mySprite setColor:ccc3(237,138,32)];
        ParentGO.Selected=YES;
    }
}

@end
