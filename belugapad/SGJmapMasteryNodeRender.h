//
//  SGJmapMNodeRender.h
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGComponent.h"
#import "SGJmapObjectProtocols.h"

//const int shadowSteps=10;

@class SGJmapMasteryNode;

@interface SGJmapMasteryNodeRender : SGComponent
{
    SGJmapMasteryNode *ParentGO;
    
    NSMutableArray *sortedChildren;
    
    CGPoint *allPerimPoints;
    ccColor4B stepColours[10];
}

-(void)draw:(int)z;
-(void)setup;

@end
