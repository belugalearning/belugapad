//
//  SGJmapCloudMotion.h
//  belugapad
//
//  Created by gareth on 13/09/2012.
//
//

#import "SGComponent.h"

@class SGJmapCloud;

@interface SGJmapCloudMotion : SGComponent
{
    SGJmapCloud *parentGO;
    
}

-(SGJmapCloudMotion*)initWithGameObject:(SGJmapCloud*)aGameObject;

@end
