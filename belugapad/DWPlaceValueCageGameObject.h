//
//  DWPlaceValueCageGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "LogPollingProtocols.h"

@interface DWPlaceValueCageGameObject : DWGameObject <LogPolling,LogPollPositioning>

@property BOOL AllowMultipleMount;
@property float PosX;
@property float PosY;
@property float ObjectValue;
@property BOOL DisableAdd;
@property BOOL DisableDel;
@property BOOL DisableAddNeg;
@property BOOL DisableDelNeg;
@property (retain) NSString *SpriteFilename;
@property (retain) NSString *PickupSpriteFilename;
@property (retain) DWGameObject *MountedObject;
@property (retain) CCSprite *mySprite;
@property BOOL Hidden;
@property int cageType;

@end
