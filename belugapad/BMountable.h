//
//  BMountable.h
//  belugapad
//
//  Created by Gareth Jenkins on 04/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"

@interface BMountable : DWBehaviour
{
    
}

-(BMountable *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;

@end
