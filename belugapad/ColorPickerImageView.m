//
//  ColorPickerImageView.m
//  belugapad
//
//  Created by Nicholas Cartwright on 16/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// TODO: Amend to generate bitmap context of just the 1 required pixel rather than entire image

#import "ColorPickerImageView.h"
#import <math.h>
#import <CoreGraphics/CoreGraphics.h>
#import <QuartzCore/CoreAnimation.h>

@interface ColorPickerImageView ()
- (void) processTouch:(NSSet*)touches;
- (NSData*) getPixelRGBADataAtPoint:(CGPoint)point;
- (CGContextRef) createRGBABitmapContextFromImage:(CGImageRef)inImage;
@end

@implementation ColorPickerImageView

@synthesize lastColorRGBAData;

- (NSData*) lastColorRGBAData
{
    if (!lastColorRGBAData)
    {
        unsigned char whiteOpaque[4] = { 0xFF, 0xFF, 0xFF, 0xFF };
        lastColorRGBAData = [NSData dataWithBytes:&whiteOpaque length:4];
    }
    return lastColorRGBAData;
}

- (void) setLastColorRGBAData:(NSData*)data
{
    if (lastColorRGBAData) [lastColorRGBAData release];
    lastColorRGBAData = data;
    [lastColorRGBAData retain];
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self processTouch:touches];
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self processTouch:touches];
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    [self processTouch:touches];
}

- (void) processTouch:(NSSet*)touches
{
    UITouch* touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self];
    
    //assumes color wheel image is circular (with == height) and that there is no image padding.
    CGFloat radius = self.image.size.width / 2;    
    CGPoint touchPointRelativeToCenter = CGPointMake(touchPoint.x - radius, touchPoint.y - radius);
    float squaredDistanceFromCenter = pow(touchPointRelativeToCenter.x, 2) + pow(touchPointRelativeToCenter.y, 2);
    if (squaredDistanceFromCenter > pow(radius, 2)) return;
    
    [self setLastColorRGBAData:[self getPixelRGBADataAtPoint:touchPoint]];
}

- (NSData*) getPixelRGBADataAtPoint:(CGPoint)point
{
    NSData* rgbaPixelData = nil;    
	CGImageRef inImage = self.image.CGImage;
    
	// Create off screen bitmap context to draw the image into. Format RGBA, 1 byte each
	CGContextRef cgctx = [self createRGBABitmapContextFromImage:inImage];
	if (cgctx == NULL) return nil; // error
	
    size_t w = CGImageGetWidth(inImage);
	size_t h = CGImageGetHeight(inImage);
	CGRect rect = { {0,0}, {w,h} }; 
	
	// Draw the image to the bitmap context.
	CGContextDrawImage(cgctx, rect, inImage); 
	
	// Get pointer to the image data associated with the bitmap context.
	unsigned char *rgbaImageData = CGBitmapContextGetData(cgctx);
    
    // offset locates the pixel in the data from x,y.  REM 4 bytes data per pixel (RGBA)
    int offset = 4 * (w * round(point.y) + round(point.x));
    
    rgbaPixelData = [NSData dataWithBytes:(rgbaImageData + offset) length:4];
	
	CGContextRelease(cgctx);
	free(rgbaImageData);
	
	return rgbaPixelData;
}

- (CGContextRef) createRGBABitmapContextFromImage:(CGImageRef)inImage
{
	
	CGContextRef    context = NULL;
	CGColorSpaceRef colorSpace;
	void *          bitmapData;
	int             bitmapByteCount;
	int             bitmapBytesPerRow;
	
	size_t pixelsWide = CGImageGetWidth(inImage);
	size_t pixelsHigh = CGImageGetHeight(inImage);
    
	bitmapBytesPerRow   = (pixelsWide * 4); // 1 byte each for RGBA
	bitmapByteCount     = (bitmapBytesPerRow * pixelsHigh);
	
	// Use the generic RGB color space.
	colorSpace = CGColorSpaceCreateDeviceRGB();
    
	if (colorSpace == NULL)
	{
		DLog(@"%@  -- Error allocating color space", stderr);
		return NULL;
	}
	
	// Allocate memory for image bitmap context data.
	bitmapData = malloc( bitmapByteCount );
	if (bitmapData == NULL) 
	{
		DLog(@"%@  -- Memory not allocated!", stderr);
		CGColorSpaceRelease( colorSpace );
		return NULL;
	}
	
	// Create bitmap context: Pre-multiplied RGBA
	context = CGBitmapContextCreate (bitmapData,
									 pixelsWide,
									 pixelsHigh,
									 8, // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaPremultipliedLast);
	if (context == NULL)
	{
		free (bitmapData);
		DLog(@"%@  -- Context not created", stderr);
	}
    
	CGColorSpaceRelease( colorSpace );
	
	return context;
}

- (void)dealloc
{
    [lastColorRGBAData release];
    [super dealloc];
}

@end
