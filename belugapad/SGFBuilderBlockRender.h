//
//  SGFBuilderBlockRender.h
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGComponent.h"
#import "SGFBuilderObjectProtocols.h"

@interface SGFBuilderBlockRender : SGComponent
{
    id<Block,RenderedObject, Touchable>ParentGO;
}

-(SGFBuilderBlockRender*)initWithGameObject:(id<Block,RenderedObject>)aGameObject;
-(void)setupSprite;
-(void)move;
-(void)destroy;

@end

