//
//  DWPlaceValueNetGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "LogPollingProtocols.h"

@class CCSprite;

@interface DWPlaceValueNetGameObject : DWGameObject <LogPolling,LogPollPositioning>

@property float PosX;
@property float PosY;
@property int myRow;
@property int myCol;
@property int myRope;
@property float ColumnValue;
@property (retain) DWGameObject *MountedObject;
@property (retain) DWGameObject *CancellingObject;
@property (retain) CCSprite *mySprite;
@property BOOL Hidden;
@property int renderType;
@property BOOL AllowMultipleMount;

@end
