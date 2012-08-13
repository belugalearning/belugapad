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
@synthesize size, position;       //Bounding properties

@synthesize rowLayoutComponent;

-(SGBtxeRow*) initWithGameWorld:(SGGameWorld*)aGameWorld
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        children=[[NSMutableArray alloc] init];
        size=CGSizeZero;
        position=CGPointZero;
        containerMgrComponent=[[SGBtxeContainerMgr alloc] initWithGameObject:(SGGameObject*)self];
        rowLayoutComponent=[[SGBtxeRowLayout alloc] initWithGameObject:(SGGameObject*)self];
    }
    return self;
}

-(void)handleMessage:(SGMessageType)messageType
{
    
}

-(void)doUpdate:(ccTime)delta
{
    
}

-(void)calculateSize
{
    
}

-(void)parseXML:(NSString *)xmlString
{
    
}

-(void)dealloc
{
    self.children=nil;
    self.containerMgrComponent=nil;
    self.rowLayoutComponent=nil;
    
    [super dealloc];
}

@end
