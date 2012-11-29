//
//  SGBtxeObjectText.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeLineBreak.h"
#import "SGBtxeTextRender.h"
#import "SGBtxeTextBackgroundRender.h"
#import "global.h"

@implementation SGBtxeLineBreak






@synthesize container;

-(SGBtxeLineBreak*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
     
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)destroy
{
    [gameWorld delayRemoveGameObject:self];
}

-(void)setupDraw
{
    
}

-(void)dealloc
{
    self.container=nil;
    
    [super dealloc];
}

@end
