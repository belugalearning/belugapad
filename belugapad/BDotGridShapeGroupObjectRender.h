//
//  BDotGridShapeGroupObjectRender.h
//  belugapad
//
//  Created by David Amphlett on 18/09/2012.
//
//

#import "DWBehaviour.h"
@class DWDotGridShapeGroupGameObject;

@interface BDotGridShapeGroupObjectRender : DWBehaviour
{
    DWDotGridShapeGroupGameObject *sg;
}

-(BDotGridShapeGroupObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)setPos;


@end
