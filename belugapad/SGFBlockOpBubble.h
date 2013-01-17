//
//  SGFBlockOpBubble.h
//  belugapad
//
//  Created by David Amphlett on 04/09/2012.
//
//

#import "SGGameObject.h"
#import "SGFBlockObjectProtocols.h"
#import "LogPollingProtocols.h"

@interface SGFBlockOpBubble : SGGameObject <Rendered, Operator, LogPolling, LogPollPositioning>

-(SGFBlockOpBubble*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition andOperators:(NSArray*)theseOperators;

@end
