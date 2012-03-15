//
//  BNLineRamblerInput.h
//  belugapad
//
//  Created by Gareth Jenkins on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"

@class DWRamblerGameObject;

@interface BNLineRamblerInput : DWBehaviour
{
    DWRamblerGameObject *ramblerGameObject;
}


-(BNLineRamblerInput *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;

@end




