//
//  SGBtxeMissingVar.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeMissingVar.h"
#import "SGBtxeTextRender.h"

@implementation SGBtxeMissingVar

@synthesize size, position;
@synthesize text, textRenderComponent;
@synthesize enabled, tag;
@synthesize hidden, rowWidth, worldPosition;
@synthesize interactive;
@synthesize disableTrailingPadding;

-(SGBtxeMissingVar*)initWithGameWorld:(SGGameWorld*)aGameWorld
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

-(void)setupDraw
{
    return;
}

-(NSString*)returnMyText
{
    return self.text;
}

-(void)activate
{
    return;
}

-(void)inflateZIndex
{
    return;
}

-(void)deflateZindex
{
    return;
}

-(void)destroy
{
    return;
}

-(void)dealloc
{
    self.text=nil;
    self.tag=nil;
    self.textRenderComponent=nil;
    
    [super dealloc];
}

@end
