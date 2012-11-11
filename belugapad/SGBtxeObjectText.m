//
//  SGBtxeObjectText.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeObjectText.h"
#import "SGBtxeTextRender.h"
#import "SGBtxeTextBackgroundRender.h"
#import "global.h"

@implementation SGBtxeObjectText

@synthesize size, position;
@synthesize text, textRenderComponent;
@synthesize enabled, tag;
@synthesize textBackgroundRenderComponent;
@synthesize originalPosition;
@synthesize usePicker;
@synthesize mount;
@synthesize hidden;

@synthesize container;

-(SGBtxeObjectText*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.text=@"";
        self.size=CGSizeZero;
        self.position=CGPointZero;
        self.tag=@"";
        self.enabled=YES;
        self.usePicker=NO;
        textRenderComponent=[[SGBtxeTextRender alloc] initWithGameObject:(SGGameObject*)self];
        textBackgroundRenderComponent=[[SGBtxeTextBackgroundRender alloc] initWithGameObject:(SGGameObject*)self];
    }
    
    return self;
}

-(id<MovingInteractive>)createADuplicate
{
    //creates a duplicate object text -- something else will need to call setupDraw and attachToRenderBase
    
    SGBtxeObjectText *dupe=[[[SGBtxeObjectText alloc] initWithGameWorld:gameWorld] autorelease];
    
    dupe.text=[[self.text copy] autorelease];
    dupe.position=self.position;
    dupe.tag=[[self.tag copy] autorelease];
    dupe.enabled=self.enabled;
    dupe.usePicker=self.usePicker;
    
    return (id<MovingInteractive>)dupe;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)destroy
{
    [self detachFromRenderBase];
    
    [gameWorld delayRemoveGameObject:self];
}

-(void)detachFromRenderBase
{
    [textBackgroundRenderComponent.sprite removeFromParentAndCleanup:YES];
    [textRenderComponent.label0 removeFromParentAndCleanup:YES];
    [textRenderComponent.label removeFromParentAndCleanup:YES];
}

-(CGPoint)worldPosition
{
    CGPoint ret=[renderBase convertToWorldSpace:self.position];
//    NSLog(@"obj-text world pos %@", NSStringFromCGPoint(ret));
    return ret;
}

-(void)setWorldPosition:(CGPoint)worldPosition
{
    self.position=[renderBase convertToNodeSpace:worldPosition];
}

-(void)attachToRenderBase:(CCNode*)theRenderBase;
{
    if(self.hidden)return;
    
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
//    NSLog(@"objtext setting position to %@", NSStringFromCGPoint(thePosition));
    
    position=thePosition;

    //TODO: auto-animate any large moves?
    
    //update positioning in text render
    [self.textRenderComponent updatePosition:position];
    
    //update positioning in background
    [self.textBackgroundRenderComponent updatePosition:position];
    
}

-(void)setupDraw
{
    if(self.hidden)return;
    
    //text render to create it's label
    [textRenderComponent setupDraw];
    
    //don't show the label if it's not enabled
    if(!self.enabled || self.usePicker)
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
    
    [super dealloc];
}

@end
