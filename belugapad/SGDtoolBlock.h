//
//  SGDtoolBlock.h
//  belugapad
//
//  Created by David Amphlett on 03/07/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGGameObject.h"
#import "SGDtoolObjectProtocols.h"

@class SGDtoolBlockRender;

@interface SGDtoolBlock : SGGameObject <Transform, Configurable, Selectable, Moveable>

@property (retain) SGDtoolBlockRender *BlockRenderComponent;

-(SGDtoolBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition;

@end
