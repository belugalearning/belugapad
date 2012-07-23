//
//  DWNBondStoreGameObject.m
//  belugapad
//
//  Created by David Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWNBondStoreGameObject.h"

@implementation DWNBondStoreGameObject

@synthesize AcceptedObjectValue;
@synthesize MountedObjects;
@synthesize Position;
@synthesize Label;
@synthesize Length;

-(void)dealloc
{
    if(MountedObjects)[MountedObjects release];
    if(Label)[Label release];
    
    [super dealloc];
}

@end
