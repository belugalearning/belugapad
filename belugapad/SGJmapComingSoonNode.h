//
//  SGJmapComingSoonNode.h
//  belugapad
//
//  Created by David Amphlett on 18/12/2012.
//
//

#import "SGGameObject.h"
#import "SGJmapObjectProtocols.h"

@interface SGJmapComingSoonNode : SGGameObject <Transform, CouchDerived, Configurable>

@property (retain) CCLayer *RenderLayer;
@property (retain) NSString *UserVisibleString;
@property (retain) NSString *spriteSuffix;

-(SGJmapComingSoonNode*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition;

@end
