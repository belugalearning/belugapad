//
//  SGFBuilderRow.m
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFBuilderRow.h"

@implementation SGFBuilderRow

@synthesize ContainedBlocks;
@synthesize Denominator;
@synthesize RenderLayer, MySprite, Position;
@synthesize RowRenderComponent;

-(SGFBuilderRow*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
    }
    
    RowRenderComponent=[[SGFBuilderRowRender alloc] initWithGameObject:self];
    
    return self;
}

-(void)setupSprite
{
    
}

@end
