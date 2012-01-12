//
//  DWGameObject.h
//
//  Created by Gareth Jenkins on 16/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DWGameWorld.h"

@class DWBehaviour;

@interface DWGameObject : NSObject {
	DWGameWorld *gameWorld;
	NSMutableArray *behaviours;
	NSMutableDictionary *localStore;
}

@property (nonatomic, retain) DWGameWorld *gameWorld;

+(DWGameObject*) createFromTemplate:(NSString*) templateName withWorld:(DWGameWorld *)gw;
+(void)parseTemplate:(NSString *)templateName inTemplateDefs:(NSDictionary *)templateDefs forObject:(DWGameObject *)gameObject;

-(NSMutableDictionary *) store;
-(DWGameObject *)initWithGameWorld:(DWGameWorld *)aGameWorld;
-(void)addBehaviour:(NSString *)behName withData:(NSDictionary *)data;
-(void)addBehaviour:(DWBehaviour*)behaviour;
-(void)logLocalStore;
-(void)logDebugMessage:(NSString *)message atLevel:(int)level;
-(void)loadData:(NSDictionary *)data;
-(void)doUpdate:(ccTime)delta;
-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload;
-(void)handleMessage:(DWMessageType)messageType;
-(void)initComplete;

-(DWBehaviour*) queryBehaviourByClass:(Class)classType;

-(void)cleanup;

@end
