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
+(CGPoint) ProjectMovementWithX: (float)x andY:(float)y forRotation:(int)rotationDeg;
+(float) DistanceBetween:(CGPoint)p1 and:(CGPoint)p2;
+(BOOL)rectContainsPoint:(CGPoint)point x:(int)x y:(int)y w:(int)w h:(int)h;


//colorspace conversion
+(ccHSL) RGBToHSL:(ccColor3B) rgb;
+(ccColor3B) HSLToRGB:(ccHSL) hsl;

@end
