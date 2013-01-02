//
//  SGBtxeRowLayout.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGComponent.h"
#import "SGBtxeProtocols.h"

@class SGBtxeRow;

@interface SGBtxeRowLayout : SGComponent
{
    SGBtxeRow *ParentGo;
}

-(void)layoutChildren;
-(void)layoutChildrenToWidth:(float)rowMaxWidth;

@end
