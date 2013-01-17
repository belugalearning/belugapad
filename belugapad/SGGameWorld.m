//
//  SGGameWorld.h
//
//  Created by Gareth Jenkins on 14/06/2012.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "SGGameWorld.h"
#import "SGGameObject.h"
#import "SGComponent.h"
#import "cocos2d.h"

@implementation SGGameWorld

//@synthesize LogBuffer;

-(SGGameWorld *)initWithGameScene:(CCLayer*)scene
{
    if( (self=[super init] )) 
    {
        mGameScene=scene;
        gameObjects=[[NSMutableArray alloc] init];        
		
		mPause = false;
		
		dirtyRemoveObjects=NO;
		removeObjects=[[NSMutableArray alloc] init];
		
        blackboard=[[SGBlackboard alloc] init];
        
    }
	return self;
}

-(SGBlackboard*) Blackboard
{
    return blackboard;
}

-(CCLayer *)GameScene
{
	return mGameScene;
}


-(void)addGameObject:(SGGameObject*)gameObject
{
    [gameObjects addObject:gameObject];
}


-(void)handleMessage:(SGMessageType)messageType
{
	if(!mPause)
	{
        int ic=[gameObjects count];
        for(int i=0; i<ic; i++)
        {
            [[gameObjects objectAtIndex:i] handleMessage:messageType];
        }
	}
}

-(void)doUpdate:(ccTime)delta
{
	//clean up / remove objects
	if(dirtyRemoveObjects)
	{
		[gameObjects removeObjectsInArray:removeObjects];
		dirtyRemoveObjects=NO;
	}
	
	if(!mPause)
	{
        int ic=[gameObjects count];
        for(int i=0; i<ic;i++)
        {
            [[gameObjects objectAtIndex:i] doUpdate:delta];
        }
	}
}


-(NSMutableArray*)AllGameObjects
{
    return gameObjects;
}

-(NSMutableArray*)AllGameObjectsCopy
{
    return [[gameObjects copy] autorelease];
}

-(void)delayRemoveGameObject:(SGGameObject*)gameObject
{
	[removeObjects addObject:gameObject];
	dirtyRemoveObjects=YES;
}


-(NSMutableArray *)removeObjects
{
	return removeObjects;
}



-(void)cleanup
{
    for (SGGameObject *go in gameObjects) {
        [go cleanup];
    }
}

-(void)dealloc
{
    
	[gameObjects release];

    [blackboard release];
    [removeObjects release];
    
	[super dealloc];
}

@end
