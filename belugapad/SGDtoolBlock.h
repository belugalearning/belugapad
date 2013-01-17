//
//  SGDtoolBlock.h
//  belugapad
//
//  Created by David Amphlett on 03/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGGameObject.h"
#import "SGDtoolObjectProtocols.h"
#import "LogPollingProtocols.h"

@class SGDtoolBlockRender;
@class SGDtoolBlockPairing;

@interface SGDtoolBlock : SGGameObject <Transform, Configurable, Selectable, Moveable, Pairable, LogPolling, LogPollPositioning>

@property (retain) SGDtoolBlockRender *BlockRenderComponent;
@property (retain) SGDtoolBlockPairing *BlockPairComponent;

-(SGDtoolBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition andType:(NSString*)thisType;

@end
