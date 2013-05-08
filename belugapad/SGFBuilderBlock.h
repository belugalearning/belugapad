//
//  SGFBuilderBlock.h
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGGameObject.h"
#import "SGFBuilderObjectProtocols.h"
#import "LogPollingProtocols.h"

@class SGFBuilderBlockRender;
@class SGFBuilderBlockTouch;

@interface SGFBuilderBlock : SGGameObject <Block,RenderedObject, Touchable>

@property (retain) SGFBuilderBlockRender *BlockRenderComponent;
@property (retain) SGFBuilderBlockTouch *BlockTouchComponent;

-(SGFBuilderBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition;

@end
