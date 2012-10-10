//
//  GooSingleSquare.m
//  belugapad
//
//  Created by gareth on 09/10/2012.
//
//

#import "GooSingleSquare.h"

@interface GooSingleSquare()
@property(nonatomic, readwrite) NSSet *chipmunkObjects;
@end

@implementation GooSingleSquare
@synthesize chipmunkObjects = _chipmunkObjects;

-(id)initWithPos:(cpVect)pos radius:(cpFloat)radiusBase count:(int)count mass:(cpFloat)massIn;
{
	if((self = [super init])){
		NSMutableSet *set = [NSMutableSet set];
		self.chipmunkObjects = set;
		
		_count = count;
		
		_rate = 5.0;
		_torque = 50000.0;
		
		cpFloat centralMass = 0.5;
		
		_centralBody = [ChipmunkBody bodyWithMass:centralMass andMoment:cpMomentForCircle(centralMass, 0, radiusBase, cpvzero)];
		[set addObject:_centralBody];
		_centralBody.pos = pos;
		
		ChipmunkShape *centralShape = [ChipmunkCircleShape circleWithBody:_centralBody radius:radiusBase offset:cpvzero];
		[set addObject:centralShape];
		centralShape.group = self;
		centralShape.layers = GRABABLE_LAYER;
		
        int jCount=0;
        
		cpFloat edgeMass = massIn/count;
		cpFloat edgeDistance = 2.0*radiusBase*cpfsin(M_PI/(cpFloat)count);
        cpFloat edgeDistanceInner=edgeDistance / ((float)jCount);
		_edgeRadius = edgeDistance/2.0;
		
		NSMutableArray *bodies = [[NSMutableArray alloc] init];
		_edgeBodies = bodies;
        
        NSMutableArray *defbodies=[[NSMutableArray alloc] init];
        
        
        cpFloat squishCoef = 1;
        cpFloat springStiffness = 30;
        cpFloat springDamping = 1;
        
		for(int i=0; i<count; i++){
            
            cpFloat radius=radiusBase;
            if(i % 2==0 || i==0) radius=sqrtf(2*(radiusBase*radiusBase));
            
			cpVect dir = cpvforangle((cpFloat)i/(cpFloat)count*2.0*M_PI);
			cpVect offset = cpvmult(dir, radius);
			
			ChipmunkBody *body = [ChipmunkBody bodyWithMass:edgeMass andMoment:INFINITY];
			body.pos = cpvadd(pos, offset);
			[bodies addObject:body];
            [defbodies addObject:body];
			
			ChipmunkShape *shape = [ChipmunkCircleShape circleWithBody:body radius:_edgeRadius offset:cpvzero];
			[set addObject:shape];
			shape.elasticity = 0;
			shape.friction = 0.1;
			shape.group = self;
			shape.layers = NORMAL_LAYER;
			
			[set addObject:[ChipmunkSlideJoint slideJointWithBodyA:_centralBody bodyB:body anchr1:offset anchr2:cpvzero min:0 max:radius*squishCoef]];
			
			cpVect springOffset = cpvmult(dir, radius + _edgeRadius);
			[set addObject:[ChipmunkDampedSpring dampedSpringWithBodyA:_centralBody bodyB:body anchr1:springOffset anchr2:cpvzero restLength:0 stiffness:springStiffness damping:springDamping]];
            
            
            if(i>0)
            {
                ChipmunkBody *connectTo=[bodies objectAtIndex:i-1];
                
                //insert spacer bodies to here
                for(int j=0;j<jCount;j++)
                {
                    cpVect jdir = cpvforangle((cpFloat)((i*(jCount+1))+j)/(cpFloat)(count*(jCount+1))*2.0*M_PI);
                    cpVect joffset = cpvmult(jdir, radius);
                    
                    ChipmunkBody *jbody = [ChipmunkBody bodyWithMass:edgeMass andMoment:INFINITY];
                    jbody.pos = cpvadd(pos, joffset);
                    [bodies addObject:jbody];
                    
                    ChipmunkShape *jshape = [ChipmunkCircleShape circleWithBody:jbody radius:_edgeRadius offset:cpvzero];
                    [set addObject:jshape];
                    jshape.elasticity = 0;
                    jshape.friction = 0.1;
                    jshape.group = self;
                    jshape.layers = NORMAL_LAYER;
                    
                    [set addObject:[ChipmunkSlideJoint slideJointWithBodyA:_centralBody bodyB:jbody anchr1:joffset anchr2:cpvzero min:0 max:radius*squishCoef]];
                    
                    cpVect springOffset = cpvmult(jdir, radius + _edgeRadius);
                    [set addObject:[ChipmunkDampedSpring dampedSpringWithBodyA:_centralBody bodyB:jbody anchr1:springOffset anchr2:cpvzero restLength:0 stiffness:springStiffness damping:springDamping]];
                    
                    connectTo=jbody;
                }
                
//                //connect last to this
//                [set addObject:[ChipmunkDampedSpring dampedSpringWithBodyA:connectTo bodyB:body anchr1:cpvzero anchr2:cpvzero restLength:0 stiffness:springStiffness damping:springDamping]];
            }
		}
        
		[set addObjectsFromArray:bodies];
		
		for(int i=0; i<bodies.count; i++){
			ChipmunkBody *a = [bodies objectAtIndex:i];
			ChipmunkBody *b = [bodies objectAtIndex:(i+1)%bodies.count];
			[set addObject:[ChipmunkSlideJoint slideJointWithBodyA:a bodyB:b anchr1:cpvzero anchr2:cpvzero min:0 max:edgeDistanceInner]];
		}
        
        for(int i=0; i<3; i+=2)
        {
			ChipmunkBody *a = [defbodies objectAtIndex:i];
			ChipmunkBody *b = [defbodies objectAtIndex:i+4];
			[set addObject:[ChipmunkSlideJoint slideJointWithBodyA:a bodyB:b anchr1:cpvzero anchr2:cpvzero min:sqrtf(2*(radiusBase*radiusBase)) max:sqrtf(2*(radiusBase*radiusBase))]];
            
            [set addObject:[ChipmunkDampedSpring dampedSpringWithBodyA:a bodyB:b anchr1:cpvzero anchr2:cpvzero restLength:0 stiffness:springStiffness damping:springDamping]];
        }

        for(int i=1; i<4; i+=2)
        {
			ChipmunkBody *a = [defbodies objectAtIndex:i];
			ChipmunkBody *b = [defbodies objectAtIndex:i+4];
			[set addObject:[ChipmunkSlideJoint slideJointWithBodyA:a bodyB:b anchr1:cpvzero anchr2:cpvzero min:radiusBase*2.1f max:radiusBase*2.1f]];
            
//            [set addObject:[ChipmunkDampedSpring dampedSpringWithBodyA:a bodyB:b anchr1:cpvzero anchr2:cpvzero restLength:0 stiffness:springStiffness damping:springDamping]];
        }
    }
	
	return self;
}

-(void)draw
{
	cpVect center = _centralBody.pos;
	
	cpVect verts[_count];
	for(int i=0; i<_count; i++){
		cpVect v = [[_edgeBodies objectAtIndex:i] pos];
		verts[i] = cpvadd(v, cpvmult(cpvnormalize(cpvsub(v, center)), _edgeRadius));
	}
	
    ccColor4F col=ccc4f(0, 220/225.0f, 0, 1);
    ccDrawFilledPoly(verts, _count, col);
    
//    ccDrawColor4F(0, 206/255.0f, 0, 1.0f);
    ccDrawColor4F(1, 1, 1, 1.0f);
    ccDrawPoly(verts, _count, YES);
    
    
    for(int j=0;j<9; j++)
    {
        cpVect jverts[_count];
        for(int k=0; k<_count; k++){
            cpVect jv = [[_edgeBodies objectAtIndex:k] pos];
            jverts[k] = cpvadd(jv, cpvmult(cpvnormalize(cpvsub(jv, center)), _edgeRadius+(j*0.75f)));
        }
        
        ccDrawColor4F(1, 1, 1, 1.0f);
        ccDrawPoly(jverts, _count, YES);
    }
    
    //higlight poly on top
    

}

- (void)dealloc
{
	[_centralBody release];
	[_edgeBodies release];
	
	self.chipmunkObjects = nil;
	
	[super dealloc];
}

@end
