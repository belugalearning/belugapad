//
//  DWPlaceValueCageGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"

@interface DWPlaceValueCageGameObject : DWGameObject

@property BOOL AllowMultipleMount;
@property float PosX;
@property float PosY;
@property float ObjectValue;
@property BOOL DisableAdd;
@property BOOL DisableDel;
@property (retain) NSString *SpriteFilename;
@property (retain) NSString *PickupSpriteFilename;
@property (retain) DWGameObject *MountedObject;
@property (retain) CCSprite *mySprite;
@property BOOL Hidden;

@end
