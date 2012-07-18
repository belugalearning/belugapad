//
//  DWNBondObjectGameObject.m
//  belugapad
//
//  Created by David Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DWNBondObjectGameObject.h"
#import "DWNBondRowGameObject.h"

@implementation DWNBondObjectGameObject

@synthesize ObjectValue;
@synthesize Position;
@synthesize MovePosition;
@synthesize MountPosition;
@synthesize Mount;
@synthesize BaseNode;
@synthesize Length;
@synthesize Label;
@synthesize InitedObject;
@synthesize IsScaled;
@synthesize IndexPos;
@synthesize NoScaleBlock;

-(DWGameObject *) initWithGameWorld:(DWGameWorld*)aGameWorld
{
    if( (self=[super initWithGameWorld:aGameWorld] )) 
    {
        Label = [[CCLabelTTF alloc]init];
    }
	return self;
}

@end