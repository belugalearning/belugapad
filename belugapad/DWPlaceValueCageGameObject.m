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
@synthesize SpriteFilename;
@synthesize PickupSpriteFilename;
@synthesize MountedObject;
@synthesize Hidden;
@synthesize mySprite;

-(void)dealloc
{
    if(SpriteFilename)[SpriteFilename release];
    if(PickupSpriteFilename)[PickupSpriteFilename release];
    if(MountedObject)[MountedObject release];
    if(mySprite)[mySprite release];
    
    [super dealloc];
}

@end
