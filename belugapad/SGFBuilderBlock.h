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

@interface SGFBuilderBlock : SGGameObject <Block,RenderedObject>

@property (retain) SGFBuilderBlockRender *BlockRenderComponent;

-(SGFBuilderBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition;

@end
