//
//  DWGameWorld.m
//
//  Created by Gareth Jenkins on 16/06/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DWGameWorld.h"
#import "DWGameObject.h"
#import "DWBehaviour.h"
//#import "GameScene.h"

@implementation DWGameWorld
@synthesize hexMap;
@synthesize LogBuffer;

-(DWGameWorld *)initWithGameScene:(CCLayer*)scene
{
    if( (self=[super init] )) 
    {
        mGameScene=scene;
        gameObjects=[[NSMutableArray alloc] init];        
        localStore=[[NSMutableDictionary alloc] init];
		[localStore retain];
		
		mPause = false;
		
		dirtyRemoveObjects=NO;
		removeObjects=[[NSMutableArray alloc] init];
		
        blackboard=[[DWBlackboard alloc] init];
        
        LogBuffer=[[NSMutableArray alloc] init];
        [LogBuffer addObject:@"time, object-template, object-address, log-description, log-data"];
    }
	return self;
}

-(DWBlackboard*) Blackboard
{
    return blackboard;
}

-(CCLayer *)GameScene
{
	return mGameScene;
}

-(DWGameObject*)addGameObjectWithTemplate:(NSString *)templateName
{
    DWGameObject *gameObject = [DWGameObject createFromTemplate:templateName withWorld:self];	
	[gameObjects addObject:gameObject];
	
	return gameObject;
}

-(void)addGameObject:(DWGameObject*)gameObject
{
    [gameObjects addObject:gameObject];
}


-(void)logDebugMessage:(NSString *)message atLevel:(int)level
{
	if(level<=DEBUG_LEVEL)
	{
		NSLog(@"lvl%d behaviour debug log: %@", level, message);
	}
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload withLogLevel:(int)logLevel
{
	if(!mPause)
	{
        int ic=[gameObjects count];
        for(int i=0; i<ic; i++)
        {
            [[gameObjects objectAtIndex:i] handleMessage:messageType andPayload:payload withLogLevel:logLevel];
        }
	}
}

-(void)doUpdate:(ccTime)delta
{
	//clean up / remove objects
	if(dirtyRemoveObjects==YES)
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

-(void)logLocalStore
{
	NSLog(@"======================================= game world ... localstore follows");
	
	for (NSObject *o in localStore) {
		NSLog(@"%@", [o description]);
	}
	
	NSLog(@"...and objects");
	
	for(DWGameObject *go in gameObjects)
	{
		[go logLocalStore];
	}
}

-(void)writeLogBufferToDiskWithKey:(NSString *)key
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    NSString *file = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@---%@.csv", key, [NSDate date]]];
    
    NSMutableString *wStr=[[NSMutableString alloc] init];
    for (int i=0; i<[LogBuffer count]; i++) {
        [wStr appendFormat:@"%@\n", [LogBuffer objectAtIndex:i]];
    }
    
    [wStr writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

-(NSMutableDictionary *) store
{
//	[gameObjects release];
//	[localStore release];
	
	return localStore;
}


-(void)delayRemoveGameObject:(DWGameObject*)gameObject
{
	[removeObjects addObject:gameObject];
	dirtyRemoveObjects=YES;
}


-(NSMutableArray *)removeObjects
{
	return removeObjects;
}

-(DWGameObject*)gameObjectWithKey:(NSString *)key andValue:(NSString *)theValue
{
    for (DWGameObject *go in gameObjects) {
        NSString *keyValue=[[go store] objectForKey:key];
        if(keyValue)
        {
            if([keyValue isEqualToString:theValue])
            {
                //this is our object, return i
                return go;
            }
        }
    }
    return nil;
}


-(void)cleanup
{
    for (DWGameObject *go in gameObjects) {
        [go cleanup];
    }
    
    [localStore removeAllObjects];
}

-(void)dealloc
{
	[localStore release];
    

    
	[gameObjects release];

    [removeObjects release];
	[super dealloc];
}

@end
