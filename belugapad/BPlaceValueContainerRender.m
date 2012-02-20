//
//  BContainerRender.m
//  belugapad
//
//  Created by Dave Amphlett on 06/02/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BPlaceValueContainerRender.h"
#import "global.h"

@implementation BPlaceValueContainerRender

-(BPlaceValueContainerRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BPlaceValueContainerRender*)[super initWithGameObject:aGameObject withData:data];
    
    //init pos x & y in case they're not set elsewhere
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_X];
    [[gameObject store] setObject:[NSNumber numberWithFloat:0.0f] forKey:POS_Y];
    
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
    NSString *sname=[[gameObject store] objectForKey:RENDER_IMAGE_NAME];
    if(!sname) sname=@"netspacer.png";
    
    mySprite=[CCSprite spriteWithFile:sname];
    [mySprite setOpacity:120];

    float x=[[[gameObject store] objectForKey:POS_X] floatValue];
    float y=[GOS_GET(POS_Y) floatValue];
    
    [mySprite setPosition:ccp(x, y)];
    
    BOOL inactive=[[[gameObject store] objectForKey:HIDDEN] boolValue];
    if(inactive)
    {
        [mySprite setVisible:NO];
    }
    
    [gameWorld.Blackboard.ComponentRenderLayer addChild:mySprite z:0];

    
}

-(void) dealloc
{
    [mySprite release];
    [super dealloc];
}


@end
