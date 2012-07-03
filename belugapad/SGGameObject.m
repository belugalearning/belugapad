//
//  SGGameObject.m
//
//  Created by Gareth Jenkins on 14/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "SGGameObject.h"
#import "SGComponent.h"


@implementation SGGameObject

@synthesize gameWorld;

-(SGGameObject *) initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if( (self=[super init] )) 
    {
        gameWorld=aGameWorld;
    
        [gameWorld addGameObject:self];
    }
	return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    [self handleMessage:messageType];
}

-(void)doUpdate:(ccTime)delta
{
    @throw [NSException exceptionWithName:@"not implemented" reason:@"not implemented" userInfo:nil];
}

-(void)cleanup
{

}

-(void)dealloc
{
    	
	[super dealloc];
}

@end
