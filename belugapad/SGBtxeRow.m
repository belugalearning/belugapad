//
//  SGBtxeRow.m
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGBtxeRow.h"
#import "SGBtxeContainerMgr.h"
#import "SGBtxeRowLayout.h"
#import "SGBtxeParser.h"

@implementation SGBtxeRow

@synthesize children, containerMgrComponent;   //Container properties
@synthesize renderLayer, forceVAlignTop;
@synthesize size, position, worldPosition;       //Bounding properties

@synthesize rowLayoutComponent;
@synthesize parserComponent;
@synthesize baseNode;

-(SGBtxeRow*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)renderLayerTarget
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        children=[[NSMutableArray alloc] init];
        self.size=CGSizeZero;
        self.position=CGPointZero;
        self.forceVAlignTop=NO;
        containerMgrComponent=[[SGBtxeContainerMgr alloc] initWithGameObject:(SGGameObject*)self];
        rowLayoutComponent=[[SGBtxeRowLayout alloc] initWithGameObject:(SGGameObject*)self];
        parserComponent=[[SGBtxeParser alloc] initWithGameObject:(SGGameObject*)self];
        
        self.renderLayer=renderLayerTarget;
    }
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(BOOL)containsObject:(id)o
{
    //just checks if o is in this row's children
    return [children containsObject:o];
}

-(void)inflateZindex
{
    self.baseNode.zOrder=99;
}
-(void)deflateZindex
{
    baseNode.zOrder=0;
}

-(void)setupDraw
{
    //create base node
    baseNode=[[CCNode alloc] init];
    self.baseNode.position=self.position;
    [renderLayer addChild:self.baseNode];
    
    //render each child
    for (id<Bounding, RenderObject> c in children) {
        [c setupDraw];
        
        //we could potentially do this separately (create, layout, attach) -- but for the moment
        // this shouldn't have a performance impact as Cocos won't do stuff with this until we
        // release the run loop
        [c attachToRenderBase:self.baseNode];
    }
    
    //layout position of stuff
    [self.rowLayoutComponent layoutChildren];

}

-(void)setPosition:(CGPoint)thePosition
{
    position=thePosition;
    self.baseNode.position=self.position;
}

-(void)animateAndMoveToPosition:(CGPoint)thePosition
{
    position=thePosition;
    [self.baseNode runAction:[CCEaseInOut actionWithAction:[CCMoveTo actionWithDuration:0.25f position:position] rate:2.0f]];
}

-(void)relayoutChildrenToWidth:(float)width
{
    [self.rowLayoutComponent layoutChildrenToWidth:width];
}

-(void)fadeInElementsFrom:(float)startTime andIncrement:(float)incrTime
{
    float incr=startTime;
    
    for(id c in children)
    {
        if([c conformsToProtocol:@protocol(FadeIn)])
        {
            [c fadeInElementsFrom:incr andIncrement:incrTime];
            incr+=incrTime;
        }
    }
}

-(void)parseXML:(NSString *)xmlString
{
    [self.parserComponent parseXML:xmlString];
}

-(void)dealloc
{
    self.children=nil;
    self.containerMgrComponent=nil;
    self.rowLayoutComponent=nil;
    self.parserComponent=nil;
    self.renderLayer=nil;
    self.baseNode=nil;
    
    [children release];
    
    [super dealloc];
}

@end
