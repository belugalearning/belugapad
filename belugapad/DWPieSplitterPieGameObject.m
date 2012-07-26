//
//  DWPieSplitterPieGameObject.m
//  belugapad
//
//  Created by David Amphlett on 06/06/2012.
//  Copyright (c) 2012 Productivity Balloon Ltd. All rights reserved.
//

#import "DWPieSplitterPieGameObject.h"

@implementation DWPieSplitterPieGameObject

@synthesize Position;
@synthesize MountPosition;
@synthesize mySprite;
@synthesize mySlices;
@synthesize slicesInMe;
@synthesize ScaledUp;
@synthesize HasSplit;
@synthesize numberOfSlices;
@synthesize touchOverlay;

-(DWGameObject *) initWithGameWorld:(DWGameWorld*)aGameWorld
{
    if( (self=[super initWithGameWorld:aGameWorld] )) 
    {
        slicesInMe=[[NSMutableArray alloc]init];
    }
	return self;
}

-(void)dealloc
{
    [slicesInMe release];
    
    if(mySprite)[mySprite release];
    if(mySlices)[mySlices release];
    if(touchOverlay)[touchOverlay release];
    
    [super dealloc];
}

@end
