//
//  SGFractionBuilderChunkRender.m
//  belugapad
//
//  Created by David Amphlett on 26/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "SGFractionObjectProtocols.h"
#import "SGFractionBuilderChunkRender.h"
#import "SGFractionObject.h"
#import "SGFractionChunk.h"
#import "BLMath.h"
#import "ToolConsts.h"

@interface SGFractionBuilderChunkRender()
{
    CCSprite *fractionSprite;
}

@end

@implementation SGFractionBuilderChunkRender

-(SGFractionBuilderChunkRender*)initWithGameObject:(id<ConfigurableChunk, MoveableChunk>)aGameObject
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
    id<Configurable> myParent=ParentGO.MyParent;
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/chunk.png")];
    ParentGO.MySprite=s;
    [s setOpacity:0];
    [s setPosition:ParentGO.Position];
    
    [s runAction:[CCFadeIn actionWithDuration:0.5f]];
    
    if(myParent.AutoShadeNewChunks){
        [s setColor:ccc3(0,255,0)];
        ParentGO.Selected=YES;
    }
    
    [ParentGO.RenderLayer addChild:s];
}

-(BOOL)amIProximateTo:(CGPoint)location
{
    CCSprite *curSprite=ParentGO.MySprite;
    //NSLog(@"loc: %@ bb: %@", NSStringFromCGPoint(location), NSStringFromCGRect(curSprite.boundingBox));
    //location=[ParentGO.MySprite convertToNodeSpace:location];
    
    if(CGRectContainsPoint(curSprite.boundingBox, location))
        return YES;

    else
        return NO;
}

-(void)moveChunk
{
    CCSprite *curSprite=ParentGO.MySprite;
    [curSprite setPosition:ParentGO.Position];
}

-(void)changeChunkSelection
{
    CCSprite *curSprite=ParentGO.MySprite;
    
    if(ParentGO.Selected)
    {
        ParentGO.Selected=NO;
        [curSprite setColor:ccc3(255,255,255)];
    }
    else
    {
        ParentGO.Selected=YES;
        [curSprite setColor:ccc3(0,255,0)];
    }
}

-(BOOL)checkForChunkDropIn:(id<Configurable>)thisObject
{
    fractionSprite=thisObject.FractionSprite;
    
    CGPoint adjPos=[thisObject.BaseNode convertToNodeSpace:ParentGO.Position];
    
    if(CGRectContainsPoint(fractionSprite.boundingBox, adjPos))
        return YES;
    else
        return NO;
}


@end
