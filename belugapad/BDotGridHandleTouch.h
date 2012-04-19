//
//  BDotGridHandleTouch.h
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"


@interface BDotGridHandleTouch : DWBehaviour
{
    
    
    
}

-(BDotGridHandleTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)handleMove;
-(void)handleResize;

@end
