//
//  SGJmapCloudMotion.m
//  belugapad
//
//  Created by gareth on 13/09/2012.
//
//

#import "SGJmapCloudMotion.h"

@implementation SGJmapCloudMotion

-(SGJmapCloudMotion*)initWithGameObject:(SGJmapCloud*)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        parentGO=aGameObject;
    }
    
    return self;
}


@end
