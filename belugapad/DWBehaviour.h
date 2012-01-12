//
//  DWBehaviour.h
//
//  Created by Gareth Jenkins on 28/07/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DWGameObject.h"

//to avoid cyclical reference
//@class DWGameObject;
//@class DWGameWorld;

@interface DWBehaviour : NSObject
{
	@public DWGameObject *gameObject;
	@public DWGameWorld *gameWorld;
	//NSMutableDictionary *localStore;
	
}

-(DWBehaviour *)initWithGameObject:(DWGameObject *)aGameObject withData:(NSDictionary*) data;
-(void)logDebugMessage:(NSString *)message atLevel:(int)level;
-(void)logLocalStore;
-(void)addObject:(NSObject *)object toStoreWithKey:(NSString *)key;
-(void)doUpdate:(ccTime)delta;
-(void)handleMessage:(DWMessageType)messageType;
-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload;
-(DWGameObject *)parentGameObject;
-(void)cleanup;

@end
