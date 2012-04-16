//
//  DWDotGridHandleGameObject.h
//  belugapad
//
//  Created by David Amphlett on 13/04/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWGameObject.h"

typedef enum {
    kMoveHandle=0,
    kResizeHandle=1
} HandleType;

@interface DWDotGridHandleGameObject : DWGameObject

@property HandleType handleType;
@property CGPoint Position;

@end
