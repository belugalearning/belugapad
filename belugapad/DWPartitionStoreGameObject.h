//
//  DWPartitionStoreGameObject.h
//  belugapad
//
//  Created by David Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"

@interface DWPartitionStoreGameObject : DWGameObject

@property float AcceptedObjectValue;
@property (retain) NSMutableArray *MountedObjects;
@property CGPoint Position;


@end
