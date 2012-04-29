//
//  BLongDivGameObject.h
//  belugapad
//
//  Created by David Amphlett on 28/04/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWBehaviour.h"
@class DWLongDivGameObject;

@interface BLongDivGameObjectRender : DWBehaviour
{
    DWLongDivGameObject *obj;
}

-(BLongDivGameObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)switchSelection;

@end
