//
//  SGFractionBuilderChunk.m
//  belugapad
//
//  Created by David Amphlett on 24/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "global.h"
#import "SGFractionBuilderChunk.h"
#import "SGFractionObject.h"
#import "BLMath.h"
#import "ToolConsts.h"

@interface SGFractionBuilderChunk()
{
    CCSprite *fractionSprite;
}

@end

@implementation SGFractionBuilderChunk

-(SGFractionBuilderChunk*)initWithGameObject:(id<Configurable, Moveable, Interactive>)aGameObject
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

-(void)createChunk
{
    
}

-(void)removeChunk
{
    
}

-(void)ghostChunk
{
    fractionSprite=ParentGO.FractionSprite;
    int adjMarkerPos=ParentGO.MarkerPosition+1;
    float leftPos=fractionSprite.position.x-(fractionSprite.contentSize.width/2);
    
    if([ParentGO.GhostChunks count]>0)
    {
        for(CCSprite *s in ParentGO.GhostChunks)
        {
            CCMoveTo *moveAct=[CCMoveTo actionWithDuration:0.3f position:ccp(leftPos,s.position.y)];
            CCAction *cleanUp=[CCCallBlock actionWithBlock:^{[s removeFromParentAndCleanup:YES];}];
            CCSequence *sequence=[CCSequence actions:moveAct, cleanUp, nil];
            [s runAction:sequence];
//            [s removeFromParentAndCleanup:YES];
            
        }
    }
    
    [ParentGO.GhostChunks removeAllObjects];
    
    for(int i=0;i<adjMarkerPos;i++)
    {
        CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/separator.png")];
        float xPos=fractionSprite.position.x+(fractionSprite.contentSize.width/2);
        float sectionSize=fractionSprite.contentSize.width/adjMarkerPos;
        
        [s setPosition:ccp(xPos, fractionSprite.position.y)];
        
        [ParentGO.BaseNode addChild:s];
        [s runAction:[CCMoveTo actionWithDuration:0.5f position:ccp(leftPos+((i+1)*sectionSize),0)]];
        
        [ParentGO.GhostChunks addObject:s];
    }
}


@end
