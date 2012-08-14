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

-(void)attachToRenderBase:(CCNode*)renderBase;
{
    //TODO: add background (at z-1)
    
    [renderBase addChild:textRenderComponent.label];
}

-(void)setPosition:(CGPoint)thePosition
{
    position=thePosition;
    
    //update positioning in text render
    [self.textRenderComponent updatePosition:position];
    
    //TODO: update positioning in background
    
}

-(void)setupDraw
{
    //text render to create it's label
    [textRenderComponent setupDraw];
    
    //set size to size of cclabelttf
    self.size=self.textRenderComponent.label.contentSize;
    
    //TODO: create background (to same width as text)
    
}

-(void)dealloc
{
    self.text=nil;
    self.tag=nil;
    self.textRenderComponent=nil;
    
    [super dealloc];
}

@end
