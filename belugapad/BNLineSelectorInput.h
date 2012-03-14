//
//  BNLineSelectorInput.h
//  belugapad
//
//  Created by David Amphlett on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWSelectorGameObject;

@interface BNLineSelectorInput : DWBehaviour
{
    DWSelectorGameObject *selector;
}


-(BNLineSelectorInput *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;

@end
