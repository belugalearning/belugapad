//
//  DWDotGridShapeGroupGameObject.m
//  belugapad
//
//  Created by David Amphlett on 17/09/2012.
//
//

#import "DWDotGridShapeGroupGameObject.h"

@implementation DWDotGridShapeGroupGameObject

@synthesize shapesInMe;
@synthesize resizeHandle;
@synthesize firstAnchor;
@synthesize lastAnchor;
@synthesize hasLabels;

-(void)dealloc
{
    self.resizeHandle=nil;
    self.shapesInMe=nil;
    self.firstAnchor=nil;
    self.lastAnchor=nil;
    [super dealloc];
}
@end
