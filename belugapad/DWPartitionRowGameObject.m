//
//  DWPartitionRowGameObject.m
//  belugapad
//
//  Created by David Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWPartitionRowGameObject.h"

@implementation DWPartitionRowGameObject

@synthesize MaximumValue;
@synthesize MountedObjects;
@synthesize Locked;
@synthesize Position;
@synthesize Length;
@synthesize BaseNode;

-(DWGameObject *) initWithGameWorld:(DWGameWorld*)aGameWorld
{
    if( (self=[super initWithGameWorld:aGameWorld] )) 
    {
        MountedObjects = [[NSMutableArray alloc]init];
    }
	return self;
}

@end
