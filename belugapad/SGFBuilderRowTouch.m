//
//  SGFbuilderRowTouch.m
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFbuilderRowTouch.h"


#import "SGComponent.h"
#import "global.h"

@implementation SGFBuilderRowTouch

-(SGFBuilderRowTouch*)initWithGameObject:(id<Row,RenderedObject, Touchable>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)checkTouch:(CGPoint)location
{
    CGPoint newLoc=[ParentGO.MySprite convertToNodeSpace:location];
    
    if(ParentGO.DenominatorUpButton)
    {
        if(CGRectContainsPoint(ParentGO.DenominatorUpButton.boundingBox,newLoc))
        {
            [self touchDenominatorUp];
        }
    }
    if(ParentGO.DenominatorDownButton)
    {
        if(CGRectContainsPoint(ParentGO.DenominatorDownButton.boundingBox,newLoc))
        {
            [self touchDenominatorDown];
        }
    }
}

-(void)touchDenominatorUp
{
    [ParentGO setRowDenominator:1];
}

-(void)touchDenominatorDown
{
    [ParentGO setRowDenominator:-1];
}


@end
