//
//  BNWheelObjectRender.h
//  belugapad
//
//  Created by David Amphlett on 08/10/2012.
//
//

#import "DWBehaviour.h"
@class DWNWheelGameObject;

@interface BNWheelObjectRender : DWBehaviour
{
    DWNWheelGameObject *w;
}

-(BPieSplitterSliceObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)moveSprite;
-(void)moveSpriteHome;
-(void)handleTap;


@end
