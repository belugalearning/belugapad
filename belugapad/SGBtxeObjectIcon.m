//
//  SGBtxeObjectIcon.m
//  belugapad
//
//  Created by gareth on 01/10/2012.
//
//

#import "SGBtxeObjectIcon.h"
#import "SGBtxeIconRender.h"

@implementation SGBtxeObjectIcon

@synthesize size, position, originalPosition;
@synthesize enabled, tag;
@synthesize iconRenderComponent, iconTag;

@synthesize container;
@synthesize mount;
@synthesize hidden;

-(SGBtxeObjectIcon*)initWithGameWorld:(SGGameWorld*) aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        size=CGSizeZero;
        position=CGPointZero;
        tag=@"";
        iconTag=@"";
        enabled=YES;
        
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
    position=thePos;
    
    [self.iconRenderComponent updatePosition:position];
}

-(void)setupDraw
{
    if(self.hidden)return;
    
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
