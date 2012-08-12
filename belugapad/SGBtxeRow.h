//
//  SGBtxeRow.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"

@class SGBtxeRowLayout;

@interface SGBtxeRow : SGGameObject <Container, Bounding, Parser>
{
    NSMutableArray *children;
}

@property (retain) SGBtxeRowLayout *rowLayoutComponent;

@end
