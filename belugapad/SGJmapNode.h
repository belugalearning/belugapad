//
//  SGJmapNodeGO.h
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGGameObject.h"
#import "SGJmapObjectProtocols.h"

@class SGJmapNodeRender;

@interface SGJmapNode : SGGameObject <Transform, ProximityResponder>

@property (retain) SGJmapNodeRender* NodeRenderComponent;

-(SGJmapNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition;

@end
