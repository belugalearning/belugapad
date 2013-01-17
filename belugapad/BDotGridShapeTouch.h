//
//  BDotGridShapeTouch.h
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWDotGridShapeGameObject;


@interface BDotGridShapeTouch : DWBehaviour
{
    
    DWDotGridShapeGameObject *shape;
    
}

-(BDotGridShapeTouch *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)checkTouchSwitchSelection:(CGPoint)location;
-(void)resizeShape:(CGPoint)location;
-(void)moveShape:(CGPoint)location;

@end
