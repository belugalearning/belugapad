//
//  BLMath.m
//  belugapad
//
//  Created by Gareth Jenkins on 05/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BLMath.h"

@implementation BLMath

+(float) DotProductOf:(CGPoint)v1 and:(CGPoint)v2
{
	return (v1.x * v2.x) + (v1.y * v2.y);
}

+(CGPoint) AddVector:(CGPoint)v1 toVector:(CGPoint)v2
{
	return CGPointMake(v1.x+v2.x, v1.y+v2.y);
}

+(CGPoint) SubtractVector:(CGPoint)v1 from:(CGPoint)v2
{
	return CGPointMake(v2.x-v1.x, v2.y-v1.y);
}

+(CGPoint) ProjectMovementWithX: (float)x andY:(float)y forRotation:(int)rotationDeg
{
	float radAngle=2*M_PI*((float)rotationDeg/360);
	float sinA=sinf(radAngle);
	float cosA=cosf(radAngle);
	float toX=cosA*x - sinA*y;
	float toY=sinA*x + cosA*y;
	CGPoint pos=CGPointMake(-toX, toY);	
	return pos;
}

+(float) DistanceBetween:(CGPoint)p1 and:(CGPoint)p2
{
	float a=p2.x-p1.x;
	float b=p2.y-p1.y;
	if(a<0.0f)a=-a;
	if(b<0.0f)b=-b;
	
	return sqrtf((a*a)+(b*b));
}

+(BOOL)rectContainsPoint:(CGPoint)point x:(int)x y:(int)y w:(int)w h:(int)h
{
	if(x<=point.x &&
	   point.x <= x+w &&
	   y<=point.y &&
	   point.y<=y+h)
		return YES;
	else
		return NO;
}

/*
 Calculate HSL from RGB
 Hue is in degrees
 Lightness is between 0 and 1
 Saturation is between 0 and 1
 */
+(ccHSL) RGBToHSL:(ccColor3B) color
{
    ccColor4F c1;
    c1.r= (float)color.r/255.0f;
    c1.g= (float)color.g/255.0f;
    c1.b= (float)color.b/255.0f;
    
    double themin,themax,delta;
    ccHSL c2;
    
    themin = MIN(c1.r,MIN(c1.g,c1.b));
    themax = MAX(c1.r,MAX(c1.g,c1.b));
    delta = themax - themin;
    c2.l = (themin + themax) / 2;
    c2.s = 0;
    if (c2.l > 0 && c2.l < 1)
        c2.s = delta / (c2.l < 0.5 ? (2*c2.l) : (2-2*c2.l));
    c2.h = 0;
    if (delta > 0) {
        if (themax == c1.r && themax != c1.g)
            c2.h += (c1.g - c1.b) / delta;
        if (themax == c1.g && themax != c1.b)
            c2.h += (2 + (c1.b - c1.r) / delta);
        if (themax == c1.b && themax != c1.r)
            c2.h += (4 + (c1.r - c1.g) / delta);
        c2.h *= 60;
    }
    return(c2);
}

+(ccColor3B) HSLToRGB:(ccHSL) c1
{
    ccColor4F c2,sat,ctmp;
    
    while (c1.h < 0)
        c1.h += 360;
    while (c1.h > 360)
        c1.h -= 360;
    
    if (c1.h < 120) {
        sat.r = (120 - c1.h) / 60.0;
        sat.g = c1.h / 60.0;
        sat.b = 0;
    } else if (c1.h < 240) {
        sat.r = 0;
        sat.g = (240 - c1.h) / 60.0;
        sat.b = (c1.h - 120) / 60.0;
    } else {
        sat.r = (c1.h - 240) / 60.0;
        sat.g = 0;
        sat.b = (360 - c1.h) / 60.0;
    }
    sat.r = MIN(sat.r,1);
    sat.g = MIN(sat.g,1);
    sat.b = MIN(sat.b,1);
    
    ctmp.r = 2 * c1.s * sat.r + (1 - c1.s);
    ctmp.g = 2 * c1.s * sat.g + (1 - c1.s);
    ctmp.b = 2 * c1.s * sat.b + (1 - c1.s);
    
    if (c1.l < 0.5) {
        c2.r = c1.l * ctmp.r;
        c2.g = c1.l * ctmp.g;
        c2.b = c1.l * ctmp.b;
    } else {
        c2.r = (1 - c1.l) * ctmp.r + 2 * c1.l - 1;
        c2.g = (1 - c1.l) * ctmp.g + 2 * c1.l - 1;
        c2.b = (1 - c1.l) * ctmp.b + 2 * c1.l - 1;
    }
    
    ccColor3B color;
    color.r = c2.r * 255;
    color.g = c2.g * 255;
    color.b = c2.b * 255;
    return(color);
}

@end
