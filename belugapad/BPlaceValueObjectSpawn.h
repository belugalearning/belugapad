//
//  BPlaceValueObjectSpawn.h
//  belugapad
//
//  Created by David Amphlett on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DWBehaviour.h"
@class DWPlaceValueCageGameObject;

@interface BPlaceValueObjectSpawn : DWBehaviour
{
    DWPlaceValueCageGameObject *c;
}


-(BPlaceValueObjectSpawn *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)spawnObject;
@end
