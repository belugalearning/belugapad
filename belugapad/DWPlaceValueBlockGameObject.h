//
//  DWPlaceValueBlockGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"

@interface DWPlaceValueBlockGameObject : DWGameObject

@property (retain) DWGameObject *Mount;
@property float ObjectValue;
@property (retain) NSString *PickupSprite;
@property (retain) CCSprite *mySprite;
@property (retain) NSString *SpriteFilename;



@end
