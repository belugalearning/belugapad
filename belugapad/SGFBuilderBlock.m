//
//  SGFBuilderBlock.m
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFBuilderBlock.h"
#import "SGFBuilderBlockRender.h"
#import "SGFBuilderBlockTouch.h"

@implementation SGFBuilderBlock
@synthesize Denominator, TemporaryDenominator, TemporaryNumerator;
@synthesize ParentRow;

@synthesize RenderLayer, MySprite, Position;
@synthesize BlockRenderComponent;
@synthesize BlockTouchComponent;

-(SGFBuilderBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
    }
    
    BlockRenderComponent=[[SGFBuilderBlockRender alloc]initWithGameObject:self];
    BlockTouchComponent=[[SGFBuilderBlockTouch alloc]initWithGameObject:self];
    
    return self;
}

-(BOOL)checkTouch:(CGPoint)location
{
    return [BlockTouchComponent checkTouch:location];
}

-(void)setup
{
    [BlockRenderComponent setupSprite];
}

-(void)move
{
    [BlockRenderComponent move];
}

-(void)destroy
{
    [BlockRenderComponent destroy];
}

@end
