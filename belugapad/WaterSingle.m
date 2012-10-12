//
//  GooSingle.m
//  belugapad
//
//  Created by gareth on 08/10/2012.
//
//

#import "WaterSingle.h"

@interface WaterSingle()
@property(nonatomic, readwrite) NSSet *chipmunkObjects;
@end

@implementation WaterSingle
@synthesize chipmunkObjects = _chipmunkObjects;

-(id)initWithPos:(cpVect)pos radius:(cpFloat)radius count:(int)count mass:(cpFloat)massIn;
{
	if((self = [super init])){
		NSMutableSet *set = [NSMutableSet set];
		self.chipmunkObjects = set;
		
		_count = count;
		
		_rate = 5.0;
		_torque = 50000.0;
		
		cpFloat centralMass = 0.5;
		
		_centralBody = [ChipmunkBody bodyWithMass:centralMass andMoment:cpMomentForCircle(centralMass, 0, radius, cpvzero)];
		[set addObject:_centralBody];
		_centralBody.pos = pos;
		
		ChipmunkShape *centralShape = [ChipmunkCircleShape circleWithBody:_centralBody radius:radius offset:cpvzero];
		[set addObject:centralShape];
		centralShape.group = self;
		centralShape.layers = GRABABLE_LAYER;
		
		cpFloat edgeMass = massIn/count;
		cpFloat edgeDistance = 2.0*radius*cpfsin(M_PI/(cpFloat)count);
		_edgeRadius = edgeDistance/2.0;
		
		NSMutableArray *bodies = [[NSMutableArray alloc] initWithCapacity:count];
		_edgeBodies = bodies;
        
        ChipmunkBody *crossBody1, *crossBody2;
        cpVect crossSpringAnchor1, crossSpringAnchor2;
        
        cpFloat sideSquish1=0.1;
        cpFloat sideSpringStiffness1=3;
        cpFloat sideSpringDamping1=1;
        
        cpFloat squishCoef = sideSquish1;
        cpFloat springStiffness = sideSpringStiffness1;
		cpFloat springDamping = sideSpringDamping1;
        
		for(int i=0; i<count; i++){
            
			cpVect dir = cpvforangle((cpFloat)i/(cpFloat)count*2.0*M_PI);
			cpVect offset = cpvmult(dir, radius);
			
			ChipmunkBody *body = [ChipmunkBody bodyWithMass:edgeMass andMoment:INFINITY];
			body.pos = cpvadd(pos, offset);
			[bodies addObject:body];
			
			ChipmunkShape *shape = [ChipmunkCircleShape circleWithBody:body radius:_edgeRadius offset:cpvzero];
			[set addObject:shape];
			shape.elasticity = 0;
			shape.friction = 0.7;
			shape.group = self;
			shape.layers = NORMAL_LAYER;
			
			[set addObject:[ChipmunkSlideJoint slideJointWithBodyA:_centralBody bodyB:body anchr1:offset anchr2:cpvzero min:0 max:radius*squishCoef]];
			
			cpVect springOffset = cpvmult(dir, radius + _edgeRadius);
			[set addObject:[ChipmunkDampedSpring dampedSpringWithBodyA:_centralBody bodyB:body anchr1:springOffset anchr2:cpvzero restLength:0 stiffness:springStiffness damping:springDamping]];
            
		}
		
        
		[set addObjectsFromArray:bodies];
		
//		for(int i=0; i<count; i++){
//			ChipmunkBody *a = [bodies objectAtIndex:i];
//			ChipmunkBody *b = [bodies objectAtIndex:(i+1)%count];
//			[set addObject:[ChipmunkSlideJoint slideJointWithBodyA:a bodyB:b anchr1:cpvzero anchr2:cpvzero min:0 max:edgeDistance]];
//		}
		
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
	
    ccColor4F col=ccc4f(1.0f, 1.0f, 1.0f, 0.7f);
    ccDrawFilledPoly(verts, _count, col);

    ccDrawColor4F(1.0f, 1.0f, 1.0f, 1.0f);
    ccDrawPoly(verts, _count, YES);
}


- (void)dealloc
{
	[_centralBody release];
	[_edgeBodies release];
	
	self.chipmunkObjects = nil;
	
	[super dealloc];
}

@end