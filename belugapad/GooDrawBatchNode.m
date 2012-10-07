//
//  GooDrawBatchNode.m
//  belugapad
//
//  Created by gareth on 07/10/2012.
//
//

#import "GooDrawBatchNode.h"

@implementation GooDrawBatchNode

-(GooDrawBatchNode*)initWithSpace:(ChipmunkSpace*)thespace
{
    if(self=[super init])
    {
        cSpace=thespace;
        
    }
    
    return self;
}

-(void)draw {
    
    for (ChipmunkShape *cs in cSpace.shapes) {
        
        if([cs isKindOfClass:[ChipmunkCircleShape class]])
        {
            ChipmunkCircleShape *csc=(ChipmunkCircleShape*)cs;
            ccDrawCircle(csc.body.pos, csc.radius, csc.body.angle, 20, YES);
            
        }
        
        if([cs isKindOfClass:[ChipmunkPolyShape class]])
        {
            ccDrawCircle(cs.body.pos, 5, cs.body.angle, 20, YES);
            
        }
    }

}

-(void)dealloc
{
    
    [super dealloc];
}

@end
