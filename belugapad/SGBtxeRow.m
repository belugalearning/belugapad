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
@synthesize renderLayer;
@synthesize size, position, worldPosition;       //Bounding properties

@synthesize rowLayoutComponent;
@synthesize parserComponent;

-(SGBtxeRow*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)renderLayerTarget
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        children=[[NSMutableArray alloc] init];
        size=CGSizeZero;
        position=CGPointZero;
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

-(void)setupDraw
{
    //create base node
    baseNode=[[CCNode alloc] init];
    baseNode.position=self.position;
    [renderLayer addChild:baseNode];
    
    //render each child
    for (id<Bounding, RenderObject> c in children) {
        [c setupDraw];
        
        //we could potentially do this separately (create, layout, attach) -- but for the moment
        // this shouldn't have a performance impact as Cocos won't do stuff with this until we
        // release the run loop
        [c attachToRenderBase:baseNode];
    }
    
    //layout position of stuff
    [self.rowLayoutComponent layoutChildren];

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
    
    [children release];
    [baseNode release];
    
    [super dealloc];
}

@end
