//
//  SGFBuilderBlockRender.m
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFBuilderBlockRender.h"
#import "SGFBuilderBlock.h"

@implementation SGFBuilderBlockRender

-(SGFBuilderBlockRender*)initWithGameObject:(id<Block,RenderedObject>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)setupSprite
{
    
}

@end
