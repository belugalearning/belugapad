//
//  DWPartitionObjectGameObject.h
//  belugapad
//
//  Created by David Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"

@class DWPartitionRowGameObject;

@interface DWPartitionObjectGameObject : DWGameObject

@property float ObjectValue;
@property CGPoint Position;
@property CGPoint MovePosition;
@property CGPoint MountPosition;
@property (retain) DWPartitionRowGameObject *Mount;
@property (retain) CCNode *BaseNode;
@property int Length;
@property (retain) CCLabelTTF *Label;

@end
