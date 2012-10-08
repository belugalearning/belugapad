//
//  GooDrawBatchNode.m
//  belugapad
//
//  Created by gareth on 07/10/2012.
//
//

#import "GooDrawBatchNode.h"
#import "GooSingle.h"

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

    for(GooSingle *gs in self.gooShapes)
    {
        [gs draw];
    }
    
//    for (ChipmunkShape *cs in cSpace.shapes) {
//        
//        if([cs isKindOfClass:[ChipmunkCircleShape class]])
//        {
//            ChipmunkCircleShape *csc=(ChipmunkCircleShape*)cs;
//            ccDrawCircle(csc.body.pos, csc.radius, csc.body.angle, 20, YES);
//            
//        }
//        
//        if([cs isKindOfClass:[ChipmunkPolyShape class]])
//        {
//            ChipmunkPolyShape *csp=(ChipmunkPolyShape*)cs;
//            cpPolyShape *cpps=(cpPolyShape*)csp.shape;
//            
//            ccColor4F col=ccc4f(1.0f, 1.0f, 1.0f, 1.0f);
//            
//            ccDrawFilledPoly(cpps->tVerts, cpps->numVerts, col);
//        }
//    }

}

-(void)dealloc
{
    
    [super dealloc];
}

@end
