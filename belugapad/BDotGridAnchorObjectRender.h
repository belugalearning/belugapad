//
//  BDotGridAnchorObjectRender.h
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"
@class DWDotGridAnchorGameObject;

@interface BDotGridAnchorObjectRender : DWBehaviour
{
    DWDotGridAnchorGameObject *anch;
}

-(BDotGridAnchorObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)switchSelection;


@end
