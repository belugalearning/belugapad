//
//  SGFbuilderRowTouch.m
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFBuilderBlockTouch.h"


#import "SGComponent.h"
#import "global.h"

@implementation SGFBuilderBlockTouch

-(SGFBuilderBlockTouch*)initWithGameObject:(id<Block,RenderedObject,Touchable>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(BOOL)checkTouch:(CGPoint)location
{
    
    if(CGRectContainsPoint(ParentGO.MySprite.boundingBox, location))
    {
        NSLog(@"has hit a block");
        return YES;
    }
    
    return NO;
}


@end
