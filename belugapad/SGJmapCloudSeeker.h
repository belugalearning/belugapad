//
//  SGJmapCloudSeeker.h
//  belugapad
//
//  Created by gareth on 13/09/2012.
//
//

#import "SGComponent.h"

@class SGJmapCloud;

@interface SGJmapCloudSeeker : SGComponent
{
    SGJmapCloud *parentGO;
}

-(SGJmapCloudSeeker*)initWithGameObject:(SGJmapCloud*)aGameObject;

@end
