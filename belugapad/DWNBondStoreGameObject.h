//
//  DWNBondStoreGameObject.h
//  belugapad
//
//  Created by David Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"

@interface DWNBondStoreGameObject : DWGameObject

@property float AcceptedObjectValue;
@property (retain) NSMutableArray *MountedObjects;
@property CGPoint Position;
@property (retain) NSString *Label;
@property int Length;


@end