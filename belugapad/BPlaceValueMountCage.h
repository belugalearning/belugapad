//
//  BMount.h
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWPlaceValueCageGameObject;
@class DWPlaceValueNetGameObject;

@interface BPlaceValueMountCage : DWBehaviour
{
    BOOL evalUp;
    BOOL evalLeft;
    DWPlaceValueCageGameObject *c;
}

-(BPlaceValueMountCage *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;

@end
