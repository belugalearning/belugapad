//
//  DWBehaviour.m
//
//  Created by Gareth Jenkins on 28/07/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DWBehaviour.h"

@implementation DWBehaviour

-(DWBehaviour *)initWithGameObject:(DWGameObject *)aGameObject withData:(NSDictionary*) data
{
    if( (self=[super init] )) 
    {
        gameObject=aGameObject;
        gameWorld=[gameObject gameWorld];
        
        //add data - this will overwrite stuff
        for (NSString *k in [data allKeys]) {
            [self logDebugMessage:[[data objectForKey:k] description] atLevel:5];
            
            //copy the data from template definition
            
            NSObject *oc =[[data objectForKey:k] copy];
            NSString *kc=[k copy];
            
            [self addObject:oc toStoreWithKey:kc];
            
            [oc release];
            [kc release];
            
            //[self addObject:[[data objectForKey:k] copy] toStoreWithKey:[k copy]];
        }

        [self logDebugMessage:[NSString stringWithFormat:@"inited a %@", [self class]] atLevel:5];
    }
	return self;
}

-(void)addObject:(NSObject *) object toStoreWithKey:(NSString *)key
{
	[[gameObject store] setObject:object forKey:key];
}

-(void)logDebugMessage:(NSString *)message atLevel:(int)level
{
		if(level<=DEBUG_LEVEL)
		{
			DLog(@"%@ lvl%d behaviour debug log: %@", [self description], level, message);
		}
}

-(void)logLocalStore
{
	DLog(@"===== behaviour: %@ ... localstore follows", [self class]);
	
	for(NSString *key in [[gameObject store] allKeys])
	{
		DLog(@"%@ == %@", key, [[[gameObject store] objectForKey:key] description]);
	}
	
}

-(void)handleMessage:(DWMessageType)messageType;
{
    [self handleMessage:messageType andPayload:nil];
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
   
}

-(DWGameObject *)parentGameObject
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
