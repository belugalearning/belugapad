//
//  BDotGridHandleTouch.h
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWDotGridHandleGameObject;

@interface BDotGridHandleTouch : DWBehaviour
{
    
    DWDotGridHandleGameObject *handle;
    
}

-(BDotGridHandleTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setCurrentHandle:(CGPoint)hitLoc;
-(void)resizeShape:(CGPoint)hitLoc;
-(void)moveShape:(CGPoint)hitLoc;


@end
