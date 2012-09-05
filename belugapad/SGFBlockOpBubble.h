//
//  SGFBlockOpBubble.h
//  belugapad
//
//  Created by David Amphlett on 04/09/2012.
//
//

#import "SGGameObject.h"
#import "SGFBlockObjectProtocols.h"

@interface SGFBlockOpBubble : SGGameObject <Rendered, Operator>

-(SGFBlockOpBubble*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition;

@end
