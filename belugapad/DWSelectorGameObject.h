//
//  DWSelectorGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"

@class DWRamblerGameObject;


@interface DWSelectorGameObject : DWGameObject

@property CGPoint pos;
@property CGPoint BasePos;
@property (retain) NSMutableArray *PopulateVariableNames;
@property (retain) DWRamblerGameObject *WatchRambler;

@end
