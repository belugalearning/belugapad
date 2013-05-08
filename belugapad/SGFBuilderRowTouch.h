//
//  SGFbuilderRowTouch.h
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFBuilderObjectProtocols.h"
#import "SGComponent.h"

@interface SGFBuilderRowTouch : SGComponent
{
    id<Row,RenderedObject, Touchable>ParentGO;
}

-(BOOL)checkTouch:(CGPoint)location;

@end