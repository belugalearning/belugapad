//
//  SGJmapCloudRender.m
//  belugapad
//
//  Created by gareth on 13/09/2012.
//
//

#import "SGJmapCloudRender.h"

@implementation SGJmapCloudRender

-(SGJmapCloudRender*)initWithGameObject:(SGJmapCloud*)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        parentGO=aGameObject;
    }
    
    return self;
}

@end
