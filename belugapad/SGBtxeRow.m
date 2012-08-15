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

@implementation SGBtxeRow

@synthesize children, containerMgrComponent;   //Container properties
@synthesize renderLayer;
@synthesize size, position;       //Bounding properties

@synthesize rowLayoutComponent;

-(SGBtxeRow*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)renderLayerTarget
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        children=[[NSMutableArray alloc] init];
        size=CGSizeZero;
        position=CGPointZero;
        containerMgrComponent=[[SGBtxeContainerMgr alloc] initWithGameObject:(SGGameObject*)self];
        rowLayoutComponent=[[SGBtxeRowLayout alloc] initWithGameObject:(SGGameObject*)self];
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

-(void)parseXML:(NSString *)xmlString
{
    
}

-(void)dealloc
{
    self.children=nil;
    self.containerMgrComponent=nil;
    self.rowLayoutComponent=nil;
    self.renderLayer=nil;
    
    [children release];
    [baseNode release];
    
    [super dealloc];
}

@end
