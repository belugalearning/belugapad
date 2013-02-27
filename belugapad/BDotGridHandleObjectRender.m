//
//  BDotGridHandleObjectRender.m
//  belugapad
//
//  Created by Dave Amphlett on 30/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BDotGridHandleObjectRender.h"
#import "DWDotGridHandleGameObject.h"
#import "global.h"
#import "ToolConsts.h"
#import "BLMath.h"
#import "DWGameObject.h"
#import "AppDelegate.h"
#import "LoggingService.h"
#import "LogPoller.h"

@implementation BDotGridHandleObjectRender

-(BDotGridHandleObjectRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BDotGridHandleObjectRender*)[super initWithGameObject:aGameObject withData:data];
    handle=(DWDotGridHandleGameObject*)gameObject;
    
    //init pos x & y in case they're not set elsewhere
   
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    LoggingService *loggingService = ac.loggingService;
    [loggingService.logPoller registerPollee:(id<LogPolling>)handle];
    
    
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        CCSprite *mySprite=handle.mySprite;
        if(!mySprite) 
        {
            [self setSprite];
            [self setSpritePos];            
        }
    }
    
    if (messageType==kDWmoveSpriteToPosition) {
        
        [self setSpritePos];
    }
    if(messageType==kDWupdateSprite)
    {
        
        if(!handle.mySprite) { 
            [self setSprite];
        }
        
        
        [self setSpritePos];
    }
    if(messageType==kDWdismantle)
    {
        [[handle.mySprite parent] removeChild:handle.mySprite cleanup:YES];
        
        [gameWorld delayRemoveGameObject:handle];
    }
}



-(void)setSprite
{    
    NSString *spriteFileName=@"";

    
    if(handle.handleType==kMoveHandle) spriteFileName=@"/images/dotgrid/move.png";
    if(handle.handleType==kResizeHandle) spriteFileName=@"/images/dotgrid/resize.png";
    
    handle.mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", spriteFileName]))];
    [handle.mySprite setPosition:handle.Position];
    
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [handle.mySprite setTag:2];
        [handle.mySprite setOpacity:0];
    }
    
    
    
    [handle.RenderLayer addChild:handle.mySprite z:10];
    
    [spriteFileName release];
}

-(void)setSpritePos
{
    [handle.mySprite setPosition:[gameWorld.Blackboard.ComponentRenderLayer convertToNodeSpace:handle.Position]];
}

-(void) dealloc
{
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    LoggingService *loggingService = ac.loggingService;
    [loggingService.logPoller unregisterPollee:(id<LogPolling>)handle];
    [super dealloc];
}

@end
