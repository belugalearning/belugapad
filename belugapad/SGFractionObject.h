//
//  SGFractionObject.h
//  belugapad
//
//  Created by David Amphlett on 23/07/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "SGGameObject.h"
#import "SGFractionObjectProtocols.h"

@class SGFractionBuilderRender;
@class SGFractionBuilderMarker;
@class SGFractionBuilderChunk;

@interface SGFractionObject: SGGameObject <Configurable, Interactive, Moveable>

@property (retain) SGFractionBuilderRender *RenderComponent;
@property (retain) SGFractionBuilderMarker *MarkerComponent;
@property (retain) SGFractionBuilderChunk *ChunkComponent;


-(SGFractionObject*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition;

@end
