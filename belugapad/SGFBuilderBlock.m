//
//  SGFBuilderBlock.m
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFBuilderBlock.h"

@implementation SGFBuilderBlock
@synthesize Denominator, TemporaryDenominator, TemporaryNumerator;
@synthesize ParentRow;

-(SGFBuilderBlock*) initWithGameWorld:(SGGameWorld*)aGameWorld andRenderLayer:(CCLayer*)aRenderLayer andPosition:(CGPoint)aPosition
{
    if(self=[super initWithGameWorld:aGameWorld])
    {
//        self.RenderLayer=aRenderLayer;
//        self.Position=aPosition;
    }
    
    return self;
}

-(void)move
{
    
}


@end
