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
@class BHexMap;

@interface DWGameWorld : NSObject
{
	
	CCLayer *mGameScene;
   
	NSMutableDictionary *localStore;
	NSMutableArray *gameObjects;
    
	bool mPause;
	
	bool dirtyRemoveObjects;
	NSMutableArray *removeObjects;
    BHexMap *hexMap;
    
    DWBlackboard *blackboard;
	
}
@property (nonatomic,retain) BHexMap *hexMap;
@property (nonatomic, readonly) DWBlackboard *Blackboard;


-(NSMutableDictionary *) store;
-(DWGameWorld *)initWithGameScene:(CCLayer *)scene;

-(CCLayer *)GameScene;

-(void)logLocalStore;
-(void)logDebugMessage:(NSString *)message atLevel:(int)level;
-(DWGameObject*)addGameObjectWithTemplate:(NSString *)templateName;
-(void)addGameObject:(DWGameObject*)gameObject;
-(void)doUpdate:(ccTime)delta;
-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload;

-(void)delayRemoveGameObject:(DWGameObject *)gameObject;

-(NSMutableArray*)removeObjects;

-(void)cleanup;

@end
