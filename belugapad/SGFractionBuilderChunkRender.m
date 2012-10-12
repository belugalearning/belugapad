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
#import "SGFbuilderFraction.h"
#import "SGFbuilderChunk.h"
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
    ParentGO.Position=ccp(ParentGO.Position.x+((s.contentSize.width*ParentGO.ScaleX)/2),ParentGO.Position.y);
    [s setOpacity:0];
    [s setScaleX:ParentGO.ScaleX];
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
    
    float PosXLeft = curSprite.position.x-((curSprite.contentSize.width*curSprite.scaleX)/2);
    float PosYleft = curSprite.position.y-((curSprite.contentSize.height*curSprite.scaleY)/2);
    
    CGRect hitBox = CGRectMake(PosXLeft, PosYleft, (curSprite.contentSize.width*curSprite.scaleX), (curSprite.contentSize.height*curSprite.scaleY));
    
    
    //NSLog(@"loc: %@ bb: %@", NSStringFromCGPoint(location), NSStringFromCGRect(curSprite.boundingBox));
    //location=[ParentGO.MySprite convertToNodeSpace:location];
    
    if(CGRectContainsPoint(hitBox, location))
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
    
    id<Configurable,Interactive>OldHost=ParentGO.CurrentHost;
    id<Configurable,Interactive>PotentialNewHost=(id<Configurable,Interactive>)thisObject;
    
    if(OldHost.Divisions!=PotentialNewHost.Divisions)return NO;
    
    CGPoint adjPos=[thisObject.BaseNode convertToNodeSpace:ParentGO.Position];
//    CGPoint adjPos=ParentGO.Position;
    
    if(CGRectContainsPoint(fractionSprite.boundingBox, adjPos))
        return YES;
    else
        return NO;
}

-(void)returnToParentSlice
{
    id<Configurable,Interactive>fraction=ParentGO.CurrentHost;
    fractionSprite=fraction.FractionSprite;
    
    float leftPos=fractionSprite.position.x-(fractionSprite.contentSize.width/2);
    float halfOfChunk=(ParentGO.MySprite.contentSize.width*ParentGO.MySprite.scaleX)/2;
    float posOnFraction=fractionSprite.contentSize.width/(fraction.MarkerPosition+1);
    float adjPosOnFraction=posOnFraction*[fraction.Chunks indexOfObject:ParentGO];
    

    CGPoint myNewPos=ccp(leftPos+halfOfChunk+adjPosOnFraction,fractionSprite.position.y);
    myNewPos=[fraction.BaseNode convertToWorldSpace:myNewPos];
    
    [ParentGO.MySprite runAction:[CCMoveTo actionWithDuration:0.1f position:myNewPos]];
}

@end
