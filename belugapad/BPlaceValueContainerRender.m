//
//  BContainerRender.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueContainerRender.h"
#import "global.h"
#import "DWPlaceValueCageGameObject.h"

@implementation BPlaceValueContainerRender

-(BPlaceValueContainerRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueContainerRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    c.PosX=0.0f;
    c.PosY=0.0f;
    
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
    NSString *sname=@"/images/placevalue/netspacer.png";
    
    mySprite=[CCSprite spriteWithFile:BUNDLE_FULL_PATH(([NSString stringWithFormat:@"%@", sname]))];
    [mySprite setOpacity:120];
    c.mySprite=mySprite;

    float x=c.PosX;
    float y=c.PosY;
    
    [mySprite setPosition:ccp(x, y)];
    
    BOOL inactive=c.Hidden;
    if(inactive)
        [mySprite setVisible:NO];
    
    if(gameWorld.Blackboard.inProblemSetup)
    {
        [mySprite setTag:1];
        [mySprite setOpacity:0];
    }
    [gameWorld.Blackboard.ComponentRenderLayer addChild:mySprite z:0];

    
}

-(void) dealloc
{
    [mySprite release];
    [super dealloc];
}


@end
