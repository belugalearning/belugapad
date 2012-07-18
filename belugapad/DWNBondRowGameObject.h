//
//  DWNBondRowGameObject.h
//  belugapad
//
//  Created by David Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"

@interface DWNBondRowGameObject : DWGameObject

@property float MaximumValue;
@property (retain) NSMutableArray *MountedObjects;
@property BOOL Locked;
@property CGPoint Position;
@property int Length;
@property (retain) CCNode *BaseNode;



@end