//
//  SGFBuilderRow.m
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFBuilderRow.h"
#import "SGFBuilderRowRender.h"
#import "SGFBuilderRowTouch.h"

@implementation SGFBuilderRow

@synthesize ContainedBlocks;
@synthesize Denominator;
@synthesize RenderLayer, MySprite, Position;
@synthesize DenominatorDownButton, DenominatorUpButton;
@synthesize RowRenderComponent;
@synthesize RowTouchComponent;

-(SGFBuilderRow*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
        self.RenderLayer=aRenderLayer;
        self.Position=aPosition;
    }
    
    RowRenderComponent=[[SGFBuilderRowRender alloc] initWithGameObject:self];
    RowTouchComponent=[[SGFBuilderRowTouch alloc] initWithGameObject:self];
    
    return self;
}

-(void)checkTouch:(CGPoint)location
{
    [RowTouchComponent checkTouch:location];
}

-(void)setup
{
    [RowRenderComponent setupSprite];
}

-(void)setRowDenominator:(int)incr
{
    Denominator+=incr;
    
    if(Denominator<0)
        Denominator=0;
    
    NSLog(@"current denominator is %d", Denominator);
}

@end
