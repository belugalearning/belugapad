//
//  DWNWheelGameObject.m
//  belugapad
//
//  Created by David Amphlett on 08/10/2012.
//
//

#import "DWNWheelGameObject.h"

@implementation DWNWheelGameObject

@synthesize mySprite;
@synthesize SpriteFileName;
@synthesize Position;

-(void)dealloc
{
    self.mySprite=nil;
    
    [super dealloc];
}

@end
