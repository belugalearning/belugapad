//
//  SGComponent.m
//
//  Created by Gareth Jenkins on 14/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "SGComponent.h"

@implementation SGComponent

-(SGComponent *)initWithGameObject:(SGGameObject *)aGameObject
{
    if( (self=[super init] )) 
    {
        gameObject=aGameObject;
        gameWorld=[gameObject gameWorld];
        
    }
	return self;
}

-(void)handleMessage:(SGMessageType)messageType;
{
    [self handleMessage:messageType];
}


-(SGGameObject *)parentGameObject
{
	return gameObject;
}

-(void)doUpdate:(ccTime)delta
{
	//do nothing
}

-(void)cleanup
{
    
}

-(void)dealloc
{
	//[localStore release];
	
	[super dealloc];
}

@end
