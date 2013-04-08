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
    ContainedBlocks=[[NSMutableArray alloc]init];
    
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

-(void)splitFraction
{
    NSLog(@"need to split fraction. current denominator is %d", Denominator);
    
    if([ContainedBlocks count]>0)
    {
        for(id<RenderedObject> go in ContainedBlocks)
        {
            [go destroy];
        }
    }
    
    for(int i=0;i<Denominator;i++)
    {
        NSLog(@"%d new block time!", i);
    }
}

-(void)setRowDenominator:(int)incr
{
    int oldDenominator=Denominator;
    
    Denominator+=incr;
    
    if(Denominator<0)
        Denominator=0;
    
    if(oldDenominator!=Denominator)
    {
        [self splitFraction];
    }
    

}

-(void)destroy
{
    [RowRenderComponent destroy];
}

@end
