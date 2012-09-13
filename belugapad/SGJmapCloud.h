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

@interface SGJmapCloud : SGGameObject <Transform, ProximityResponder>

@property SGJmapCloudMotion *motionComponent;
@property SGJmapCloudSeeker *seekerComponent;
@property SGJmapCloudRender *renderComponent;

@end
