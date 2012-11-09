//
//  SGBtxeObjectOperator.m
//  belugapad
//
//  Created by gareth on 07/11/2012.
//
//

#import "SGBtxeObjectOperator.h"

#import "SGBtxeTextRender.h"
#import "SGBtxeTextBackgroundRender.h"
#import "global.h"

@implementation SGBtxeObjectOperator

@synthesize size, position, originalPosition;
@synthesize text, textRenderComponent;
@synthesize enabled, tag, container;

@synthesize textBackgroundRenderComponent;
@synthesize valueOperator;

@synthesize mount;

-(SGBtxeObjectOperator*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        text=@"";
        size=CGSizeZero;
        position=CGPointZero;
        tag=@"";
        enabled=YES;
        valueOperator=@"";
        
        textRenderComponent=[[SGBtxeTextRender alloc] initWithGameObject:(SGGameObject*)self];
        textBackgroundRenderComponent=[[SGBtxeTextBackgroundRender alloc] initWithGameObject:(SGGameObject*)self];
    }
    
    return self;
}

-(id<MovingInteractive>)createADuplicate
{
    SGBtxeObjectOperator *dupe=[[[SGBtxeObjectOperator alloc] initWithGameWorld:gameWorld]autorelease];

    dupe.text=[[self.text copy] autorelease];
    dupe.position=self.position;
    dupe.tag=[[self.tag copy] autorelease];
    dupe.enabled=self.enabled;
    dupe.valueOperator=[[self.valueOperator copy] autorelease];
    
    return (id<MovingInteractive>)dupe;
}



-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)setValueOperator:(NSString *)theValueOperator
{
    if(valueOperator)[valueOperator release];
    valueOperator=theValueOperator;
    
    self.text=theValueOperator;
}

-(CGPoint)worldPosition
{
    return [renderBase convertToNodeSpace:self.position];
}

-(void)setWorldPosition:(CGPoint)worldPosition
{
    self.position=[renderBase convertToNodeSpace:worldPosition];
}

-(void)attachToRenderBase:(CCNode*)theRenderBase
{
    renderBase=theRenderBase;
    
    [renderBase addChild:textBackgroundRenderComponent.sprite];
    [renderBase addChild:textRenderComponent.label0];
    [renderBase addChild:textRenderComponent.label];
}

-(void)inflateZIndex
{
    textBackgroundRenderComponent.sprite.zOrder=99;
    [textRenderComponent inflateZindex];
}

-(void)deflateZindex
{
    textBackgroundRenderComponent.sprite.zOrder=0;
    [textRenderComponent deflateZindex];
}

-(void)setPosition:(CGPoint)thePosition
{
    position=thePosition;

    //update positioning in text render
    [self.textRenderComponent updatePosition:position];
    
    //update positioning in background
    [self.textBackgroundRenderComponent updatePosition:position];
    
}

-(void)setupDraw
{
    //text render to create it's label
    [textRenderComponent setupDraw];
    
    //don't show the label if it's not enabled
    if(!self.enabled)
    {
        textRenderComponent.label.visible=NO;
        textRenderComponent.label0.visible=NO;
    }
    
    //set size to size of cclabelttf plus the background overdraw size (the background itself is currently stretchy)
    self.size=CGSizeMake(self.textRenderComponent.label.contentSize.width+BTXE_OTBKG_WIDTH_OVERDRAW_PAD, self.textRenderComponent.label.contentSize.height);
    
    
    //background sprite to text (using same size)
    [textBackgroundRenderComponent setupDrawWithSize:self.size];
    
}

-(void)activate
{
    self.enabled=YES;
    
    self.textRenderComponent.label.visible=self.enabled;
    self.textRenderComponent.label0.visible=self.enabled;
}

-(void)returnToBase
{
    self.position=self.originalPosition;
}

-(void)dealloc
{
    self.text=nil;
    self.tag=nil;
    self.textRenderComponent=nil;
    self.textBackgroundRenderComponent=nil;
    self.container=nil;
    self.valueOperator=nil;
    
    [super dealloc];
}


@end
