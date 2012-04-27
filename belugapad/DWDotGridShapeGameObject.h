//
//  DWDotGridShapeGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"
@class DWDotGridHandleGameObject;

@interface DWDotGridShapeGameObject : DWGameObject

@property (retain) NSMutableArray *tiles;
@property (retain) DWDotGridHandleGameObject *moveHandle;
@property (retain) DWDotGridHandleGameObject *resizeHandle;
@property BOOL Disabled;

@end
