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

-(void)initComplete
{
    [self handleMessage:kSGonGameObjectInitComplete];
}

-(SGGameObject *) initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if( (self=[super init] )) 
    {
        gameWorld=aGameWorld;
    
    }
	return self;
}

-(void)handleMessage:(SGMessageType)messageType andPayload:(NSDictionary *)payload withLogLevel:(int)logLevel
{
    @throw [NSException exceptionWithName:@"not implemented" reason:@"not implemented" userInfo:nil];
}

-(void)handleMessage:(SGMessageType)messageType
{
    [self handleMessage:messageType andPayload:nil withLogLevel:0];
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
