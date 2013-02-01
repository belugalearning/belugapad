//
//  BContainerRender.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueContainerRender.h"
#import "global.h"
#import "DWPlaceValueNetGameObject.h"
#import "LoggingService.h"
#import "LogPoller.h"
#import "AppDelegate.h"

@implementation BPlaceValueContainerRender

-(BPlaceValueContainerRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueContainerRender*)[super initWithGameObject:aGameObject withData:data];
   
    n=(DWPlaceValueNetGameObject*)aGameObject;
    
    //init pos x & y in case they're not set elsewhere
    n.PosX=0.0f;
    n.PosY=0.0f;
    
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    LoggingService *loggingService = ac.loggingService;
    [loggingService.logPoller registerPollee:(id<LogPolling>)n];
    
    return self;
}

-(void)handleMessage:(DWMessageType)messageType andPayload:(NSDictionary *)payload
{
    if(messageType==kDWsetupStuff)
    {
        [self setSprite];
    }
    
    if(messageType==kDWenable)
    {
        [mySprite setVisible:YES];
    }
}

-(void)setSprite
{
    NSString *sname=@"";
    
    if(n.renderType==0)
        sname=@"/images/placevalue/grid-middle.png";
    else if(n.renderType==1)
        sname=@"/images/placevalue/grid-top.png";
    else if(n.renderType==2)
        sname=@"/images/placevalue/grid-bottom.png";
    
    mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", sname]))];
    [mySprite setOpacity:127];
    n.mySprite=mySprite;

    float x=n.PosX;
    float y=n.PosY;
    
    [mySprite setPosition:ccp(x, y)];
    
    BOOL inactive=n.Hidden;
    if(inactive)
        [mySprite setVisible:NO];
    
    [gameWorld.Blackboard.ComponentRenderLayer addChild:mySprite z:0];

    
}

-(void) dealloc
{
    AppController *ac = (AppController*)[[UIApplication sharedApplication] delegate];
    LoggingService *loggingService = ac.loggingService;
    [loggingService.logPoller unregisterPollee:(id<LogPolling>)n];
    
    [super dealloc];
}


@end
