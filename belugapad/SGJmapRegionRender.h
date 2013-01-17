//
//  SGJmapRegionRender.h
//  belugapad
//
//  Created by Gareth Jenkins on 29/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGComponent.h"
#import "SGJmapRegionRender.h"

@class SGJmapRegion;

@interface SGJmapRegionRender : SGComponent
{
    SGJmapRegion *ParentGO;
    
    CGPoint *allPerimPoints;
    CGPoint *scaledPerimPoints;
    int perimCount;
    
    CCLabelTTF *rlabel;
    CCLabelTTF *rlabelshadow;
}
-(void)draw:(int)z;

@end
