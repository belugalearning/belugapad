//
//  SGGameWorld.h
//
//  Created by Gareth Jenkins on 14/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//



#import "cocos2d.h"
#import "SGModelConstants.h"
#import "SGBlackboard.h"

@class SGGameObject;
@class SGComponent;
@class CCLayer;

@interface SGGameWorld : NSObject
{
	
	CCLayer *mGameScene;
   
	NSMutableArray *gameObjects;
    
	bool mPause;
	
	bool dirtyRemoveObjects;
	NSMutableArray *removeObjects;
    
    SGBlackboard *blackboard;
	
}
@property (nonatomic, readonly) SGBlackboard *Blackboard;

//@property (retain, readonly) NSMutableArray *LogBuffer;


-(SGGameWorld *)initWithGameScene:(CCLayer *)scene;

-(CCLayer *)GameScene;

-(NSMutableArray*)AllGameObjects;
-(NSMutableArray*)AllGameObjectsCopy;

-(void)addGameObject:(SGGameObject*)gameObject;
-(void)doUpdate:(ccTime)delta;
-(void)handleMessage:(SGMessageType)messageType;

-(void)delayRemoveGameObject:(SGGameObject *)gameObject;

-(NSMutableArray*)removeObjects;

-(void)cleanup;

@end
