//
//  SGFBuilderRowRender.h
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFBuilderObjectProtocols.h"
#import "SGComponent.h"

@interface SGFBuilderRowRender : SGComponent
{
    id<Row,RenderedObject, Touchable>ParentGO;
}

-(void)setupSprite;

@end
