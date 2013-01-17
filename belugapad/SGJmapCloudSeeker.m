//
//  SGJmapCloudSeeker.m
//  belugapad
//
//  Created by gareth on 13/09/2012.
//
//

#import "SGJmapCloudSeeker.h"

@implementation SGJmapCloudSeeker

-(SGJmapCloudSeeker*)initWithGameObject:(SGJmapCloud*)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        parentGO=aGameObject;
    }
    
    return self;
}


@end
