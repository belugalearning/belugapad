//
//  SGFBuilderBlockRender.m
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "global.h"
#import "SGFBuilderBlockRender.h"
#import "SGFBuilderBlock.h"

@implementation SGFBuilderBlockRender

-(SGFBuilderBlockRender*)initWithGameObject:(id<Block,RenderedObject, Touchable>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)setupSprite
{
    if(ParentGO.MySprite)return;
    
    CCSprite *s=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(@"/images/fractions/chunk.png")];
    s.position=ParentGO.Position;
    [ParentGO.RenderLayer addChild:s];
    
    ParentGO.MySprite=s;
    
}

-(void)destroy
{
    
}

@end
