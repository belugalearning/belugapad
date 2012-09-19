//
//  DWDotGridShapeGroupGameObject.h
//  belugapad
//
//  Created by David Amphlett on 17/09/2012.
//
//

#import "DWGameObject.h"
#import "DWDotGridShapeGameObject.h"

@interface DWDotGridShapeGroupGameObject : DWGameObject

@property (retain) NSMutableArray *shapesInMe;
@property (retain) DWDotGridShapeGameObject *resizeShape;
@property (retain) DWDotGridAnchorGameObject *firstAnchor;
@property (retain) DWDotGridAnchorGameObject *lastAnchor;

@end
