//
//  BPlaceValueObjectSpawn.h
//  belugapad
//
//  Created by David Amphlett on 09/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DWBehaviour.h"

@interface BPlaceValueObjectSpawn : DWBehaviour

-(BPlaceValueObjectSpawn *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)spawnObject;
@end
