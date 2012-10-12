//
//  BMountable.h
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"

@class DWNBondObjectGameObject;

@interface BNBondMountable : DWBehaviour
{
    DWNBondObjectGameObject *pogo;
}

-(BNBondMountable *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;

@end
