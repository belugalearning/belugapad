//
//  SGFbuilderRowTouch.h
//  belugapad
//
//  Created by David Amphlett on 08/04/2013.
//
//

#import "SGFBuilderObjectProtocols.h"
#import "SGComponent.h"

@interface SGFBuilderBlockTouch : SGComponent
{
    id<Block,RenderedObject,Touchable>ParentGO;
}

-(BOOL)checkTouch:(CGPoint)location;

@end