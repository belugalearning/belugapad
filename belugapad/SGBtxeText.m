//
//  SGBtxeText.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeText.h"
#import "SGBtxeTextRender.h"

@implementation SGBtxeText

@synthesize size, position;
@synthesize text, textRenderComponent;

-(SGBtxeText*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        text=@"";
        size=CGSizeZero;
        position=CGPointZero;
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
    self.textRenderComponent=nil;
    [super dealloc];
}

@end
