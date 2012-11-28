//
//  SGBtxeObjectIcon.m
//  belugapad
//
//  Created by gareth on 01/10/2012.
//
//

#import "SGBtxeObjectIcon.h"
#import "SGBtxeIconRender.h"
#import "SGBtxeTextBackgroundRender.h"
#import "global.h"

@implementation SGBtxeObjectIcon

@synthesize size, position, originalPosition;
@synthesize enabled, interactive, tag;
@synthesize iconRenderComponent, iconTag;
@synthesize textBackgroundRenderComponent;
@synthesize container;
@synthesize mount;
@synthesize hidden;
@synthesize assetType;

-(SGBtxeObjectIcon*)initWithGameWorld:(SGGameWorld*) aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        size=CGSizeZero;
        position=CGPointZero;
        tag=@"";
        iconTag=@"";
        enabled=YES;
        interactive=YES;
        assetType=@"Small";
        
        //todo: init render
        iconRenderComponent=[[SGBtxeIconRender alloc] initWithGameObject:self];
    }
    
    return self;
}

-(id<MovingInteractive>)createADuplicateIntoGameWorld:(SGGameWorld*)destGW
{
    //creates a duplicate object text -- something else will need to call setupDraw and attachToRenderBase
    
    SGBtxeObjectIcon *dupe=[[[SGBtxeObjectIcon alloc] initWithGameWorld:destGW] autorelease];
    
    dupe.position=self.position;
    dupe.tag=[[self.tag copy] autorelease];
    dupe.enabled=self.enabled;
    dupe.assetType=self.assetType;
    
    dupe.iconTag=[[self.iconTag copy] autorelease];
    
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

-(NSString*)returnMyText
{
    NSDictionary *iconNames=[NSDictionary dictionaryWithContentsOfFile:BUNDLE_FULL_PATH(@"/tts-objects.plist")];
    if([iconNames objectForKey:self.tag])
        return [iconNames objectForKey:self.tag];
    
    else
        return @"generic icon";
}

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime
{
    [iconRenderComponent fadeInElementsFrom:startTime andIncrement:incrTime];
}

-(CGPoint)worldPosition
{
    return [renderBase convertToWorldSpace:self.position];
    
}

-(void)setWorldPosition:(CGPoint)worldPosition
{
    self.position=[renderBase convertToNodeSpace:worldPosition];
}

-(void)setColourOfBackgroundTo:(ccColor3B)thisColour
{
    [self.textBackgroundRenderComponent setColourOfBackgroundTo:thisColour];
}

-(void)attachToRenderBase:(CCNode*)theRenderBase
{
    if(self.hidden)return;
    
    renderBase=theRenderBase;
    
    //all icons will render from the same batch, and this object's icon will attach to batch automatically.
    // so just add batch to render base if it's not already got a parent
    if(!gameWorld.Blackboard.btxeIconBatch.parent)
    {
        [renderBase addChild:gameWorld.Blackboard.btxeIconBatch];
    }
}

-(void)inflateZIndex
{
    [self.iconRenderComponent inflateZindex];
}
-(void)deflateZindex
{
    [self.iconRenderComponent deflateZindex];
}

-(void)setPosition:(CGPoint)thePos
{
    position=[gameWorld.Blackboard.RenderLayer convertToWorldSpace:thePos];
    
    CGPoint actualPos=position;
    
    if([container conformsToProtocol:@protocol(Bounding)])
    {
        id<Bounding> bc=(id<Bounding>)container;
        actualPos=ccpAdd(position, bc.position);
    }
    
    [self.iconRenderComponent updatePosition:actualPos];
}

-(void)setupDraw
{
    if(self.hidden)return;
    
    iconRenderComponent.assetType=self.assetType;
    
    [self.iconRenderComponent setupDraw];
    
    self.iconRenderComponent.sprite.visible=self.enabled;
    
    self.size=self.iconRenderComponent.sprite.contentSize;
}

-(void)activate
{
    self.enabled=YES;
    self.iconRenderComponent.sprite.visible=self.enabled;
    
}

-(void)returnToBase
{
    self.position=self.originalPosition;
}

-(void)detachFromRenderBase
{
    [iconRenderComponent.sprite removeFromParentAndCleanup:YES];
}

-(void)tagMyChildrenForIntro
{
    [iconRenderComponent.sprite setTag:3];
    [iconRenderComponent.sprite setOpacity:0];
}

-(void)destroy
{
    [self detachFromRenderBase];
    
    [gameWorld delayRemoveGameObject:self];
}

-(void)dealloc
{
    self.tag=nil;
    self.iconTag=nil;
    self.iconRenderComponent=nil;
    self.container=nil;
    
    [super dealloc];
}

@end
