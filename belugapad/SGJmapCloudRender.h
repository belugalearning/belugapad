//
//  SGJmapCloudRender.h
//  belugapad
//
//  Created by gareth on 13/09/2012.
//
//

#import "SGComponent.h"

@class SGJmapCloud;

@interface SGJmapCloudRender : SGComponent
{
    SGJmapCloud *parentGO;
}

-(SGJmapCloudRender*)initWithGameObject:(SGJmapCloud*)aGameObject;

@end
