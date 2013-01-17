//
//  BNWheelObjectRender.h
//  belugapad
//
//  Created by David Amphlett on 08/10/2012.
//
//

#import "DWBehaviour.h"
#import "CCPickerView.h"
@class DWNWheelGameObject;

@interface BNWheelObjectRender : DWBehaviour <CCPickerViewDataSource, CCPickerViewDelegate>
{
    DWNWheelGameObject *w;
}
@property (nonatomic, retain) CCPickerView *pickerView;

-(BNWheelObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data;
-(void)setSprite;
-(void)moveSprite;
-(void)moveSpriteHome;
-(void)handleTap;
-(float)returnBaseOfNumber:(int)pickerSelectionIndex;

@end
