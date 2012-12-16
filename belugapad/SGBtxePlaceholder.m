//
//  SGBtxePlaceholder.m
//  belugapad
//
//  Created by gareth on 03/11/2012.
//
//

#import "SGBtxePlaceholder.h"
#import "SGBtxeTextBackgroundRender.h"
#import "SGBtxeContainerMgr.h"
#import "SGBtxeRow.h"
#import "global.h"

@implementation SGBtxePlaceholder

@synthesize size, position, enabled, tag, worldPosition;
@synthesize textBackgroundComponent;
@synthesize container;
@synthesize targetTag;
@synthesize assetType;
@synthesize mountedObject;
@synthesize backgroundType;

-(SGBtxePlaceholder*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        size=CGSizeZero;
        position=CGPointZero;
        
        textBackgroundComponent=[[SGBtxeTextBackgroundRender alloc] initWithGameObject:(SGGameObject*)self];
    }
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(CGPoint)worldPosition
{
    return [renderBase convertToWorldSpace:self.position];
}

-(void)setWorldPosition:(CGPoint)theWorldPosition
{
    self.position=[renderBase convertToNodeSpace:theWorldPosition];
}

-(void)setupDraw
{
    //artifically set size
    
    if([self.assetType isEqualToString:@"Large"])
        size=CGSizeMake(150, 85);
    
    else if([self.assetType isEqualToString:@"Medium"])
        size=CGSizeMake(100, 57);
    
    else
        size=CGSizeMake(50, 40);
    
    if([self.backgroundType isEqualToString:@"Card"])
        size.width=170;
    

    //background sprite to text (using same size)
    [textBackgroundComponent setupDrawWithSize:self.size];
    
}

-(void)redrawBkg
{
    if(!mountedObject)return;
    
    if([mountedObject conformsToProtocol:@protocol(Bounding)])
    {
        
        CGSize thisSize=CGSizeMake(mountedObject.size.width-15, mountedObject.size.height);
        
        [textBackgroundComponent redrawBkgWithSize:thisSize];
    }

}

-(BOOL)enabled
{
    //compare tag of mount to target mount
    return ([self.mountedObject.tag isEqualToString:self.targetTag]);
}

-(void)setEnabled:(BOOL)theEnabled
{
    enabled=theEnabled;
}

-(void)duplicateAndMountThisObject:(id<MovingInteractive, NSObject>)mountObject
{
    //destroy any existing mounted object
    if(mountedObject)
    {
        [mountedObject destroy];
        self.mountedObject=nil;
    }
    
    //create a duplicate of the passed object
    id<MovingInteractive, RenderObject, NSObject> dupe=(id<MovingInteractive, RenderObject, NSObject>)[mountObject createADuplicate];
    
    dupe.mount=self;
    dupe.assetType=self.assetType;
    
    //set it up
    [dupe setupDraw];
    [dupe.textBackgroundRenderComponent setColourOfBackgroundTo:[mountObject.textBackgroundRenderComponent returnColourOfBackground]];
    
    //put on position of self
    dupe.position=ccp(self.position.x, self.position.y-2);
    dupe.originalPosition=dupe.position;
    
    //attach to same row as me
    [dupe attachToRenderBase:((SGBtxeRow*)self.container).baseNode];
    
    [self.container.containerMgrComponent addObjectToContainer:(id<Bounding>)dupe];
    //[self setContainerVisible:NO];
    
    mountedObject=dupe;
    [self redrawBkg];
}

-(void)setContainerVisible:(BOOL)visible
{
    [textBackgroundComponent setContainerVisible:visible];
}

-(void)attachToRenderBase:(CCNode *)theRenderBase
{
    renderBase=theRenderBase;
    
    //attach background to render, but stick behind other objects by default
    [renderBase addChild:textBackgroundComponent.backgroundNode z:-1];
}

-(CGRect)returnBoundingBox
{
    CGRect thisRect=CGRectMake(self.worldPosition.x-(size.width/2), self.worldPosition.y-(size.height/2),size.width,size.height);

    return thisRect;
}

-(void)deflateZindex
{
    
}

-(void)inflateZIndex
{
    
}

-(void)setPosition:(CGPoint)thePosition
{
    position=thePosition;
    
    //TODO: auto-animate any large moves?
    
    //update positioning in background
    [self.textBackgroundComponent updatePosition:position];
    
}

-(void)activate
{
    
}

-(void)destroy
{
    
}

-(void)dealloc
{
    self.mountedObject=nil;
    self.container=nil;
    self.tag=nil;
    self.textBackgroundComponent=nil;
    
    [super dealloc];
}

@end
