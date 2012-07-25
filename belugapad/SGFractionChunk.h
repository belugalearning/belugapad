//
//  SGFractionChunk.h
//  belugapad
//
//  Created by David Amphlett on 25/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "SGGameObject.h"
#import "SGFractionObjectProtocols.h"

@class SGFractionBuilderChunk;

@interface SGFractionChunk: SGGameObject <ConfigurableChunk,Moveable>



-(SGFractionChunk*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition;

@property (retain) SGFractionBuilderChunk *ChunkComponent;

@end
