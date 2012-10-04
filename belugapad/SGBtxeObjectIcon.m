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
        self.iconRenderComponent=[[SGBtxeIconRender alloc] initWithGameObject:self];
    }
    
    return self;
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
    renderBase=theRenderBase;
    
    //all icons will render from the same batch, and this object's icon will attach to batch automatically.
    // so just add batch to render base if it's not already got a parent
    if(!gameWorld.Blackboard.btxeIconBatch.parent)
    {
        [renderBase addChild:gameWorld.Blackboard.btxeIconBatch];
    }
}

-(void)setPosition:(CGPoint)thePos
{
    position=thePos;
    
    [self.iconRenderComponent updatePosition:position];
}

-(void)setupDraw
{
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

-(void)dealloc
{
    self.tag=nil;
    self.iconTag=nil;
    self.iconRenderComponent=nil;
    
    [super dealloc];
}

@end