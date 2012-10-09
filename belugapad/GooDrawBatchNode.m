//
//  GooDrawBatchNode.m
//  belugapad
//
//  Created by gareth on 07/10/2012.
//
//

#import "GooDrawBatchNode.h"
#import "GooSingle.h"
#import "BLMath.h"

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

    for(ChipmunkDampedSpring *spring in self.springShapes)
    {
        ccDrawColor4F(1, 1, 1, 1);
//        ccDrawLine(spring.bodyA.pos, spring.bodyB.pos);
        
        CGPoint line=[BLMath SubtractVector:spring.bodyA.pos from:spring.bodyB.pos];
        CGPoint lineN=[BLMath NormalizeVector:line];
        CGPoint upV=[BLMath PerpendicularLeftVectorTo:lineN];
        
        float distScalar=1.0f;
        float distScaleBase=0.25f;
        float distScaleFrom=200.0f;
        float lOfLine=[BLMath LengthOfVector:line];
        if(lOfLine<distScaleFrom)
        {
            distScalar=distScaleBase + (1-(lOfLine / distScaleFrom));
        }
        else
        {
            distScalar=distScaleBase;
        }
        
        for(int i=0; i<1; i++)
        {
            CGPoint a=[BLMath AddVector:spring.bodyA.pos toVector:[BLMath MultiplyVector:upV byScalar:i*0.75f]];
            CGPoint b=[BLMath AddVector:spring.bodyB.pos toVector:[BLMath MultiplyVector:upV byScalar:i*0.75f]];
            
            ccDrawLine(a, b);
        }
        
        int barHalfW=15;
        
        for(int j=-barHalfW; j<0; j++)
        {
            CGPoint a=[BLMath AddVector:spring.bodyA.pos toVector:[BLMath MultiplyVector:upV byScalar:j*0.75f*distScalar]];
            CGPoint b=[BLMath AddVector:spring.bodyB.pos toVector:[BLMath MultiplyVector:upV byScalar:(j+barHalfW)*0.75f*distScalar]];
            
            ccDrawLine(a, b);
        }
        
        for(int k=barHalfW; k>0; k--)
        {
            CGPoint a=[BLMath AddVector:spring.bodyA.pos toVector:[BLMath MultiplyVector:upV byScalar:k*0.75f*distScalar]];
            CGPoint b=[BLMath AddVector:spring.bodyB.pos toVector:[BLMath MultiplyVector:upV byScalar:(k-barHalfW)*0.75f*distScalar]];
            
            ccDrawLine(a, b);
        }
    }
    
    for(id<GooDraw> gs in self.gooShapes)
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
