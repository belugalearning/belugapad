//
//  SGFBlockBubble.h
//  belugapad
//
//  Created by David Amphlett on 03/09/2012.
//
//

#import "SGGameObject.h"
#import "SGFBlockObjectProtocols.h"

@interface SGFBlockBubble : SGGameObject <Rendered, Target>

-(SGFBlockBubble*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition andReplacement:(BOOL)isReplacement;

@end
