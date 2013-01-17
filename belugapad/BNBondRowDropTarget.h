//
//  BDropTarget.h
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"

@class DWNBondRowGameObject;

@interface BNBondRowDropTarget : DWBehaviour
{
    DWNBondRowGameObject *prgo;
}

-(BNBondRowDropTarget *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;

@end
