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
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/chunk.png")];
    ParentGO.MySprite=s;
    [s setOpacity:0];
    [s setPosition:ParentGO.Position];
    
    [s runAction:[CCFadeIn actionWithDuration:0.5f]];
    
    [ParentGO.RenderLayer addChild:s];
}

-(BOOL)amIProximateTo:(CGPoint)location
{
    CCSprite *curSprite=ParentGO.MySprite;
    NSLog(@"loc: %@ bb: %@", NSStringFromCGPoint(location), NSStringFromCGRect(curSprite.boundingBox));
    //location=[ParentGO.MySprite convertToNodeSpace:location];
    
    if(CGRectContainsPoint(curSprite.boundingBox, location))
    {
        NSLog(@"got chunk!");
        return YES;
    }
    else
    {
        return NO;
    }
}

-(void)moveMarkerTo:(CGPoint)location
{
    
}

@end
