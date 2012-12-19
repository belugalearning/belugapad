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
{
    bool planeUsed;
}


@property int PlaneType;
@property (retain) CCLayer *RenderLayer;
@property (retain) CCSprite *planeSprite;

@property CGPoint Destination;

-(SGJmapPaperPlane*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition andDestination:(CGPoint) aDestination;
-(NSValue*)checkTouchOnMeAt:(CGPoint)location;
@end
