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
@synthesize enabled, interactive, tag, container;

@synthesize textBackgroundRenderComponent;
@synthesize valueOperator;

@synthesize mount;
@synthesize hidden;

@synthesize assetType;
@synthesize backgroundType;

-(SGBtxeObjectOperator*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        text=@"";
        size=CGSizeZero;
        position=CGPointZero;
        tag=@"";
        enabled=YES;
        interactive=YES;
        valueOperator=@"";
        assetType=@"Small";
        backgroundType=@"Tile";
        
        textRenderComponent=[[SGBtxeTextRender alloc] initWithGameObject:(SGGameObject*)self];
        textBackgroundRenderComponent=[[SGBtxeTextBackgroundRender alloc] initWithGameObject:(SGGameObject*)self];
    }
    
    return self;
}

-(id<MovingInteractive>)createADuplicateIntoGameWorld:(SGGameWorld *)destGW
{
    SGBtxeObjectOperator *dupe=[[[SGBtxeObjectOperator alloc] initWithGameWorld:destGW]autorelease];
    
    dupe.text=[[self.text copy] autorelease];
    dupe.position=self.position;
    dupe.tag=[[self.tag copy] autorelease];
    dupe.assetType=self.assetType;
    dupe.enabled=self.enabled;
    dupe.valueOperator=[[self.valueOperator copy] autorelease];
    dupe.backgroundType=self.backgroundType;
    
    return (id<MovingInteractive>)dupe;
}

-(id<MovingInteractive>)createADuplicate
{
    return [self createADuplicateIntoGameWorld:gameWorld];
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
    if([theValueOperator isEqualToString:@"/"])
        self.text=@"÷";
}

-(NSString*)returnMyText
{
    NSString *myText=nil;
    
    myText=self.text;
    
    if([self.text isEqualToString:@"+"])
        myText=@"plus";
    if([self.text isEqualToString:@"-"])
        myText=@"minus";
    if([self.text isEqualToString:@"x"])
        myText=@"times by";
    if([self.text isEqualToString:@"%"])
        myText=@"divided by";
    if([self.text isEqualToString:@"÷"])
        myText=@"divided by";
    if([self.text isEqualToString:@"="])
        myText=@"equals";
    
    return myText;
}

-(CGPoint)worldPosition
{
    CGPoint ret=[renderBase convertToWorldSpace:self.position];
//    NSLog(@"operator world pos %@", NSStringFromCGPoint(ret));
    return ret;
}

-(void)setWorldPosition:(CGPoint)worldPosition
{
    self.position=[renderBase convertToNodeSpace:worldPosition];
}

-(void)destroy
{
    [self detachFromRenderBase];
    
    [gameWorld delayRemoveGameObject:self];
}

-(void)detachFromRenderBase
{
    [textBackgroundRenderComponent.backgroundNode removeFromParentAndCleanup:YES];
    [textRenderComponent.label0 removeFromParentAndCleanup:YES];
    [textRenderComponent.label removeFromParentAndCleanup:YES];
}

-(void)attachToRenderBase:(CCNode*)theRenderBase
{
    if(self.hidden)return;
    
    renderBase=theRenderBase;
    
    [renderBase addChild:textBackgroundRenderComponent.backgroundNode];
    [renderBase addChild:textRenderComponent.label0];
    [renderBase addChild:textRenderComponent.label];
}

-(void)inflateZIndex
{
    textBackgroundRenderComponent.backgroundNode.zOrder=99;
    [textRenderComponent inflateZindex];
}

-(void)deflateZindex
{
    textBackgroundRenderComponent.backgroundNode.zOrder=0;
    [textRenderComponent deflateZindex];
}

-(void)setPosition:(CGPoint)thePosition
{
//    NSLog(@"operator setting position to %@", NSStringFromCGPoint(thePosition));
    
    position=thePosition;

    //update positioning in text render
    [self.textRenderComponent updatePosition:position];
    
    //update positioning in background
    [self.textBackgroundRenderComponent updatePosition:position];
    
}

-(void)tagMyChildrenForIntro
{
    [textRenderComponent.label setTag:3];
    [textRenderComponent.label0 setTag:3];
    [textRenderComponent.label setOpacity:0];
    [textRenderComponent.label0 setOpacity:0];
}

-(void)setupDraw
{
    if(self.hidden)return;
    textRenderComponent.useTheseAssets=self.assetType;
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
    
    if([self.backgroundType isEqualToString:@"Card"] && [self.assetType isEqualToString:@"Large"] && size.width<170)
        size.width=170;
    
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
