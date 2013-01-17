//
//  SGJmapCloud.h
//  belugapad
//
//  Created by gareth on 13/09/2012.
//
//

#import "SGGameObject.h"
#import "SGJmapObjectProtocols.h"

@class SGJmapCloudMotion;
@class SGJmapCloudSeeker;
@class SGJmapCloudRender;

@interface SGJmapCloud : SGGameObject <Transform, ProximityResponder, ParticleRender>

@property (retain) SGJmapCloudMotion *motionComponent;
@property (retain) SGJmapCloudSeeker *seekerComponent;
@property (retain) SGJmapCloudRender *renderComponent;


-(SGJmapCloud*)initWithGameWorld:(SGGameWorld*)aGameWorld andRenderBatch:(CCSpriteBatchNode*)aRenderBatch andPosition:(CGPoint)aPosition;

@end
