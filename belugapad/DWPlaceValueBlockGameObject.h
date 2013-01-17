//
//  DWPlaceValueBlockGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWGameObject.h"
#import "LogPollingProtocols.h"

@interface DWPlaceValueBlockGameObject : DWGameObject <LogPolling,LogPollPositioning>
{
    DWGameObject *Mount1;
    DWGameObject *LastMount1;
}

@property (retain) DWGameObject *Mount;
@property (retain) DWGameObject *LastMount;
@property float ObjectValue;
@property (retain) NSString *PickupSprite;
@property (retain) CCSprite *mySprite;
@property (retain) NSString *SpriteFilename;
@property float PosX;
@property float PosY;
@property BOOL AnimateMe;
@property BOOL Selected;
@property BOOL Disabled;
@property int lastZIndex;




@end
