//
//  SGFBuilderRowRender.m
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFBuilderRowRender.h"
#import "SGComponent.h"

@implementation SGFBuilderRowRender

-(SGFBuilderRowRender*)initWithGameObject:(id<Row,RenderedObject>)aGameObject
{
    if(self=[super initWithGameObject:(SGGameObject*)aGameObject])
    {
        ParentGO=aGameObject;
    }
    
    return self;
}

-(void)setupSprite
{
    
}

@end
