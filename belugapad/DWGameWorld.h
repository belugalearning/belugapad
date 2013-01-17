//
//  DWGameWorld.h
//
//  Created by Gareth Jenkins on 16/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//



#define TEMPLATE_NAME @"TEMPLATE_NAME"


#import "cocos2d.h"
#import "DWModelConstants.h"
//#import "Global.h"
#import "DWBlackboard.h"

@class DWGameObject;
@class DWBehaviour;
@class CCLayer;
@class ToolScene;

@interface DWGameWorld : NSObject
{
	
	ToolScene *mGameScene;
   
	NSMutableDictionary *localStore;
	NSMutableArray *gameObjects;
    
	bool mPause;
	
	bool dirtyRemoveObjects;
	NSMutableArray *removeObjects;
    
    DWBlackboard *blackboard;
	
}
@property (nonatomic, readonly) DWBlackboard *Blackboard;

@property (retain, readonly) NSMutableArray *LogBuffer;


-(NSMutableDictionary *) store;
-(DWGameWorld *)initWithGameScene:(ToolScene *)scene;

-(ToolScene *)GameScene;

-(void)logLocalStore;
-(void)logDebugMessage:(NSString *)message atLevel:(int)level;
-(void)writeLogBufferToDiskWithKey:(NSString *)key;

-(DWGameObject*)addGameObjectWithTemplate:(NSString *)templateName;
-(void)populateAndAddGameObject:(DWGameObject*)originalObject withTemplateName:(NSString *)templateName;

-(NSMutableArray*)AllGameObjects;

-(void)addGameObject:(DWGameObject*)gameObject;
-(void)doUpdate:(ccTime)delta;
-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload withLogLevel:(int)logLevel;

-(void)delayRemoveGameObject:(DWGameObject *)gameObject;

-(NSMutableArray*)removeObjects;

-(DWGameObject*)gameObjectWithKey:(NSString *)key andValue:(NSString *)theValue;
-(void)logInfo:(NSString *) desc withData:(int)logData;
-(void)logInfoWithRawMessage:(NSString *)message;

-(void)cleanup;

@end
