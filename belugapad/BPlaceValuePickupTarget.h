//
//  BFloatPickupTarget.h
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWPlaceValueBlockGameObject;

@interface BPlaceValuePickupTarget : DWBehaviour
{
    DWPlaceValueBlockGameObject *b;
}


-(BPlaceValuePickupTarget *)initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;

@end
