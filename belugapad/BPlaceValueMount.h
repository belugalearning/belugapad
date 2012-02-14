//
//  BMount.h
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"

@interface BPlaceValueMount : DWBehaviour
{
    BOOL evalUp;
    BOOL evalLeft;
}

-(BPlaceValueMount *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;

@end
