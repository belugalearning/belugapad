//
//  SGBtxeRow.h
//  belugapad
//
//  Created by gareth on 11/08/2012.
//
//

#import "SGGameObject.h"
#import "SGBtxeProtocols.h"

@interface SGBtxeRow : SGGameObject <Container, Bounding, Parser>
{
    NSMutableArray *children;
}
@end
