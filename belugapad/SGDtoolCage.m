//
//  SGDtoolCage.m
//  belugapad
//
//  Created by David Amphlett on 13/08/2012.
//
//

#import "SGDtoolCage.h"
#import "SGDtoolBlock.h"
#import "global.h"

@implementation SGDtoolCage

@synthesize RenderLayer, Position;

-(SGDtoolCage*) initWithGameWorld:(SGGameWorld*)aGameWorld atPosition:(CGPoint)thisPosition andRenderLayer:(CCLayer*)aRenderLayer
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.Position=thisPosition;
        self.RenderLayer=aRenderLayer;
    }
    return self;
}


-(void)handleMessage:(SGMessageType)messageType
{
    //re-broadcast messages to components
}

-(void)doUpdate:(ccTime)delta
{
    //update of components
    
}

-(void)draw:(int)z
{
    
}

-(void)spawnNewBlock
{
    id<Configurable,Selectable,Pairable,Moveable> newblock;
    newblock=[[[SGDtoolBlock alloc] initWithGameWorld:gameWorld andRenderLayer:self.RenderLayer andPosition:self.Position] autorelease];
    newblock.MyContainer=self;
    [newblock setup];

}

-(void)removeBlockFromMe:(id)thisBlock
{
    ((id<Moveable>)thisBlock).MyContainer=nil;
}

-(void)dealloc
{
    [super dealloc];
}

@end

