//
//  SGFBlockBlock.h
//  belugapad
//
//  Created by David Amphlett on 03/09/2012.
//
//

#import "SGGameObject.h"
#import "SGFBlockObjectProtocols.h"
#import "LogPollingProtocols.h"

@interface SGFBlockBlock : SGGameObject <Moveable, Rendered, LogPolling, LogPollPositioning>

-(SGFBlockBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition;

@end
