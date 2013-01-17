//
//  BLMath.h
//  belugapad
//
//  Created by Gareth Jenkins on 05/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

typedef struct _ccHSL
{
	float	h;
	float	s;
	float l;
} ccHSL;

@interface BLMath : NSObject {
    
}

+(float)DotProductOf:(CGPoint)v1 and:(CGPoint)v2;

+(CGPoint)AddVector:(CGPoint)v1 toVector:(CGPoint)v2;
+(CGPoint)SubtractVector:(CGPoint)v1 from:(CGPoint)v2;
+(CGPoint) MultiplyVector:(CGPoint)v byScalar:(float)s;
+(CGPoint) DivideVector:(CGPoint)v byScalar:(float)s;
+(CGPoint) NormalizeVector:(CGPoint)v;
+(CGPoint) PerpendicularRightVectorTo:(CGPoint)v;
+(CGPoint) PerpendicularLeftVectorTo:(CGPoint)v;
+(float) LengthOfVector:(CGPoint)v;
+(CGPoint) TruncateVector:(CGPoint)v toMaxLength:(float)l;

+(NSValue*) BoxAndYFlipCGPoint:(CGPoint)point withMaxY:(float)maxY;

+(float) angleFromNorthToLineFrom:(CGPoint)v1 to:(CGPoint)v2;
+(float) angleForVector:(CGPoint)v;
+(float) angleForNormVector:(CGPoint)v;
+(CGPoint) closestIntersectionOfLineFrom:(CGPoint)E to:(CGPoint)L againstCircle:(CGPoint)C withRadius:(float)r;

+(CGPoint) ProjectMovementWithX: (float)x andY:(float)y forRotation:(int)rotationDeg;
+(float) DistanceBetween:(CGPoint)p1 and:(CGPoint)p2;
+(BOOL)rectContainsPoint:(CGPoint)point x:(int)x y:(int)y w:(int)w h:(int)h;

+(CGPoint)offsetPosFrom:(CGPoint)p1 to:(CGPoint)p2;


//colorspace conversion
+(ccHSL) RGBToHSL:(ccColor3B) rgb;
+(ccColor3B) HSLToRGB:(ccHSL) hsl;

@end
