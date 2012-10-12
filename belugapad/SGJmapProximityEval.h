//
//  SGJmapProximityEval.h
//  belugapad
//
//  Created by Gareth Jenkins on 18/06/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SGComponent.h"
#import "SGJmapObjectProtocols.h"

@interface SGJmapProximityEval : SGComponent
{
    id<ProximityResponder, Transform, GameObject>ParentGO;
}

-(void)actOnProximityTo:(CGPoint)pos;

@end
