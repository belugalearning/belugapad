//
//  GooProtocols.h
//  belugapad
//
//  Created by gareth on 08/10/2012.
//
//

#import "ObjectiveChipmunk.h"

@protocol GooDraw

-(void)draw;

@end

@protocol GooBody

@property(readonly) ChipmunkBody *centralBody;

@end