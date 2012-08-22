//
//  SGJmapNodeRender.h
//  belugapad
//
//  Created by Gareth Jenkins on 15/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGComponent.h"
#import "SGJmapObjectProtocols.h"

@interface SGJmapNodeRender : SGComponent
{
    id<Transform, ProximityResponder> ParentGO;
}

-(void)draw:(int)z;
-(void)setup;
-(void)updatePosition:(CGPoint)pos;


@end
