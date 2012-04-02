//
//  BFloatPickupTarget.h
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"

@class DWPartitionObjectGameObject;

@interface BPartitionPickupTarget : DWBehaviour
{
    DWPartitionObjectGameObject *pogo;
}


-(BPartitionPickupTarget *)initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;

@end
