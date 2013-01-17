//
//  SGFBlockBubble.h
//  belugapad
//
//  Created by David Amphlett on 03/09/2012.
//
//

#import "SGGameObject.h"
#import "SGFBlockObjectProtocols.h"
#import "LogPollingProtocols.h"

@interface SGFBlockBubble : SGGameObject <Rendered, Target, LogPolling, LogPollPositioning>

-(SGFBlockBubble*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition andReplacement:(BOOL)isReplacement;

@end
