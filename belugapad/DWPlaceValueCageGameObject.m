//
//  DWPlaceValueCageGameObject.m
//  belugapad
//
//  Created by David Amphlett on 13/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWPlaceValueCageGameObject.h"

@implementation DWPlaceValueCageGameObject

@synthesize AllowMultipleMount;
@synthesize PosX;
@synthesize PosY;
@synthesize ObjectValue;
@synthesize DisableAdd;
@synthesize DisableDel;
@synthesize DisableAddNeg;
@synthesize DisableDelNeg;
@synthesize SpriteFilename;
@synthesize PickupSpriteFilename;
@synthesize MountedObject;
@synthesize Hidden;
@synthesize mySprite;
@synthesize cageType;

-(void)dealloc
{
    self.SpriteFilename=nil;
    self.PickupSpriteFilename=nil;
    self.MountedObject=nil;
    self.mySprite=nil;
    
    [super dealloc];
}

@end
