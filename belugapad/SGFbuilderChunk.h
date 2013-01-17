//
//  SGFractionChunk.h
//  belugapad
//
//  Created by David Amphlett on 25/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "SGGameObject.h"
#import "SGFractionObjectProtocols.h"

@class SGFractionBuilderChunkManager;
@class SGFractionBuilderChunkRender;

@interface SGFbuilderChunk: SGGameObject <ConfigurableChunk,MoveableChunk>



-(SGFbuilderChunk*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition;

@property (retain) SGFractionBuilderChunkManager *ChunkManagerComponent;
@property (retain) SGFractionBuilderChunkRender *ChunkRenderComponent;

@end
