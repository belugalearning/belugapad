//
//  BContainerRender.m
//  belugapad
//
//  Created by Gareth Jenkins on 04/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BContainerRender.h"
#import "global.h"
#import "ToolScene.h"

@implementation BContainerRender

-(BContainerRender *) initWithGameObject:(DWGameObject *) aGameObject withData:(NSDictionary *)data
{
    self=(BContainerRender*)[super initWithGameObject:aGameObject withData:data];
    
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
    if(!sname) sname=@"obj-blockholder-mount1x1.png";
    
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
    
    [[gameWorld GameScene].ForeLayer addChild:mySprite z:0];
    
}

-(void) dealloc
{
    [mySprite release];
    [super dealloc];
}


@end
