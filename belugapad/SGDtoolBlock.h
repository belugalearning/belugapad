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

@interface SGDtoolBlock : SGGameObject <Transform, Configurable, Selectable>

@property (retain) SGDtoolBlockRender *BlockRenderComponent;

-(SGDtoolBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition;

@end
