//
//  SGJmapPaperPlane.h
//  belugapad
//
//  Created by David Amphlett on 18/12/2012.
//
//

#import "SGGameObject.h"
#import "SGJmapObjectProtocols.h"

@interface SGJmapPaperPlane : SGGameObject <Transform, Drawing, ProximityResponder, Configurable>

@property int PlaneType;
@property (retain) CCLayer *RenderLayer;
@property (retain) CCSprite *planeSprite;


-(SGJmapPaperPlane*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition;
-(BOOL)checkTouchOnMeAt:(CGPoint)location;
@end
