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
#import "SGBtxeRowLayout.h"
#import "global.h"

@implementation SGBtxePlaceholder

@synthesize size, position, enabled, tag, worldPosition;
@synthesize textBackgroundComponent;
@synthesize container;
@synthesize targetTag;
@synthesize assetType;
@synthesize mountedObject;
@synthesize backgroundType;
@synthesize interactive;
@synthesize hidden, rowWidth;

-(SGBtxePlaceholder*)initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        size=CGSizeZero;
        position=CGPointZero;
        
        textBackgroundComponent=[[SGBtxeTextBackgroundRender alloc] initWithGameObject:(SGGameObject*)self];
        debugBoundingBox=YES;
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
        size=CGSizeMake(150, 0);
    
    else if([self.assetType isEqualToString:@"Medium"])
        size=CGSizeMake(100, 0);
    
    else
        size=CGSizeMake(50, 0);
    
    if([self.backgroundType isEqualToString:@"Card"] && [self.assetType isEqualToString:@"Large"])
        size.width=170;
    else if([self.backgroundType isEqualToString:@"Card"] && [self.assetType isEqualToString:@"Medium"])
        size.width=116;
    else if([self.backgroundType isEqualToString:@"Card"] && [self.assetType isEqualToString:@"Small"])
        size.width=40;
    

    //background sprite to text (using same size)
    [textBackgroundComponent setupDrawWithSize:self.size];
    
}

-(void)redrawBkg
{
    if(!self.mountedObject)return;
    
    if([self.mountedObject conformsToProtocol:@protocol(Bounding)])
    {
        
        CGSize thisSize=CGSizeMake(self.mountedObject.size.width, self.mountedObject.size.height);
        
        [textBackgroundComponent redrawBkgWithSize:thisSize];
        
        self.size=thisSize;
        
        //    id<Containable>myMount=(id<Containable>)self.mount;
        SGBtxeRow *myRow=(SGBtxeRow*)self.container;
        SGBtxeRowLayout *layoutComp=myRow.rowLayoutComponent;
        [layoutComp layoutChildren];
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
    if(self.mountedObject)
    {
        [self.container.containerMgrComponent removeObjectFromContainer:self.mountedObject];
        
        id<Interactive, NSObject> oldo=self.mountedObject;
        self.mountedObject=nil;
        
        [oldo destroy];
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
    
    self.mountedObject=dupe;
    [self redrawBkg];
}

-(void)setContainerVisible:(BOOL)visible
{
    [textBackgroundComponent setContainerVisible:visible];
}

-(void)changeVisibility:(BOOL)visibility
{
    [self setContainerVisible:visibility];
}

-(void)attachToRenderBase:(CCNode *)theRenderBase
{
    renderBase=theRenderBase;
    
    //attach background to render, but stick behind other objects by default
    [renderBase addChild:textBackgroundComponent.backgroundNode z:-1];
}

-(void)displayBoundingBox
{
    if(!drawNode){
        drawNode=[[CCDrawNode alloc]init];
        [renderBase addChild:drawNode];
    }
    
    if(debugBoundingBox)
    {
        CGRect myRect=[self returnBoundingBox];
        
        
        CGPoint points[4];
        
        points[0]=ccp(myRect.origin.x, myRect.origin.y);
        points[1]=ccp(myRect.origin.x, myRect.origin.y+myRect.size.height);
        points[2]=ccp(myRect.origin.x+myRect.size.width, myRect.origin.y+myRect.size.height);
        points[3]=ccp(myRect.origin.x+myRect.size.width, myRect.origin.y);
        
        for(int i=0;i<4;i++)
        {
            points[i]=[renderBase convertToNodeSpace:points[i]];
        }
        
        [drawNode drawPolyWithVerts:points count:4 fillColor:ccc4f(1, 1, 1, 1) borderWidth:1 borderColor:ccc4f(1, 1, 1, 1)];
    }

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
