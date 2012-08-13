//
//  SGBtxeObjectText.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeObjectText.h"
#import "SGBtxeTextRender.h"

@implementation SGBtxeObjectText

@synthesize size, position;
@synthesize text, textRenderComponent;
@synthesize enabled, tag;

-(SGBtxeObjectText*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        text=@"";
        size=CGSizeZero;
        position=CGPointZero;
        tag=@"";
        enabled=YES;
        textRenderComponent=[[SGBtxeTextRender alloc] initWithGameObject:(SGGameObject*)self];
    }
    
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)calculateSize
{
    
}

-(void)dealloc
{
    self.text=nil;
    self.tag=nil;
    self.textRenderComponent=nil;
    
    [super dealloc];
}

@end
