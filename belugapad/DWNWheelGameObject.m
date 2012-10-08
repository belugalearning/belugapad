//
//  DWNWheelGameObject.m
//  belugapad
//
//  Created by David Amphlett on 08/10/2012.
//
//

#import "DWNWheelGameObject.h"
#import "global.h"


@implementation DWNWheelGameObject

@synthesize mySprite;
@synthesize SpriteFileName;
@synthesize Position;
@synthesize RenderLayer;
@synthesize pickerViewSelection;
@synthesize pickerView;
@synthesize AssociatedGO;


-(void)dealloc
{
    self.mySprite=nil;
    self.SpriteFileName=nil;
    self.pickerViewSelection=nil;
    
    [super dealloc];
}

@end
